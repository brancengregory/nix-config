# modules/network/netbird.nix
# Self-hosted Netbird management server with Podman quadlets
# Network: 100.64.0.0/10 (CGNAT range)
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.netbird-server;
  dataDir = "/var/lib/netbird";
in {
  options.services.netbird-server = {
    enable = mkEnableOption "Netbird self-hosted management server";

    domain = mkOption {
      type = types.str;
      default = "netbird.brancen.world";
      description = "Domain for Netbird dashboard";
    };

    managementPort = mkOption {
      type = types.port;
      default = 33073;
      description = "Port for Netbird management API";
    };

    dashboardPort = mkOption {
      type = types.port;
      default = 18765;
      description = "Internal port for Netbird dashboard";
    };

    signalPort = mkOption {
      type = types.port;
      default = 10000;
      description = "Port for Netbird signal service";
    };

    turnPort = mkOption {
      type = types.port;
      default = 3478;
      description = "Port for TURN/STUN server";
    };

    postgresPort = mkOption {
      type = types.port;
      default = 5433;
      description = "Internal PostgreSQL port (isolated from system)";
    };

    redisPort = mkOption {
      type = types.port;
      default = 6380;
      description = "Internal Redis port (isolated from system)";
    };

    client = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Netbird client on this host";
      };

      managementUrl = mkOption {
        type = types.str;
        default = "https://netbird.brancen.world:33073";
        description = "URL of the Netbird management server";
      };
    };

    secrets = {
      jwtSecretFile = mkOption {
        type = types.path;
        description = "Path to JWT secret file";
      };

      adminPasswordHashFile = mkOption {
        type = types.path;
        description = "Path to admin password hash file (bcrypt)";
      };

      postgresPasswordFile = mkOption {
        type = types.path;
        description = "Path to PostgreSQL password file";
      };

      turnPasswordFile = mkOption {
        type = types.path;
        description = "Path to TURN server password file";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable Podman and quadlet
    virtualisation.containers.enable = true;
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # Create netbird user for running containers
    users.users.netbird = {
      isSystemUser = true;
      group = "netbird";
      home = dataDir;
      createHome = true;
    };
    users.groups.netbird = {};

    # Create data directories
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0750 netbird netbird -"
      "d ${dataDir}/postgres 0750 netbird netbird -"
      "d ${dataDir}/redis 0750 netbird netbird -"
      "d ${dataDir}/management 0750 netbird netbird -"
      "d ${dataDir}/signal 0750 netbird netbird -"
      "d ${dataDir}/relay 0750 netbird netbird -"
      "d ${dataDir}/client 0750 netbird netbird -"
    ];

    # PostgreSQL Quadlet
    virtualisation.oci-containers.containers.netbird-postgres = {
      image = "postgres:16-alpine";
      autoStart = true;
      ports = ["127.0.0.1:${toString cfg.postgresPort}:5432"];
      volumes = [
        "${dataDir}/postgres:/var/lib/postgresql/data"
      ];
      environment = {
        POSTGRES_DB = "netbird";
        POSTGRES_USER = "netbird";
        POSTGRES_PASSWORD_FILE = "/run/secrets/netbird-postgres-password";
      };
      extraOptions = [
        "--secret=netbird-postgres-password,type=mount,target=/run/secrets/netbird-postgres-password,uid=70,gid=70,mode=0400"
      ];
    };

    # Redis Quadlet
    virtualisation.oci-containers.containers.netbird-redis = {
      image = "redis:7-alpine";
      autoStart = true;
      ports = ["127.0.0.1:${toString cfg.redisPort}:6379"];
      volumes = [
        "${dataDir}/redis:/data"
      ];
      cmd = ["redis-server" "--appendonly" "yes" "--dir" "/data"];
    };

    # Wait for dependencies before starting management
    systemd.services."podman-netbird-management" = {
      after = ["podman-netbird-postgres.service" "podman-netbird-redis.service"];
      requires = ["podman-netbird-postgres.service" "podman-netbird-redis.service"];
      serviceConfig = {
        Restart = "always";
        RestartSec = "5";
      };
    };

    # Netbird Management Quadlet
    virtualisation.oci-containers.containers.netbird-management = {
      image = "netbirdio/management:latest";
      autoStart = true;
      ports = [
        "127.0.0.1:${toString cfg.managementPort}:33073"
        "127.0.0.1:${toString cfg.dashboardPort}:80"
      ];
      volumes = [
        "${dataDir}/management:/var/lib/netbird"
        "${pkgs.writeTextFile {
          name = "management.json";
          text = builtins.toJSON {
            Stuns = [
              {
                Proto = "udp";
                URI = "stun:netbird.brancen.world:${toString cfg.turnPort}";
                Username = "";
                Password = "";
              }
            ];
            TURNConfig = {
              Turns = [
                {
                  Proto = "udp";
                  URI = "turn:netbird.brancen.world:${toString cfg.turnPort}";
                  Username = "netbird";
                  Password = "$TURN_PASSWORD";
                }
              ];
              CredentialsTTL = "12h";
              Secret = {};
              TimeBasedCredentials = false;
            };
            Signal = {
              Proto = "http";
              URI = "http://localhost:10000";
              Username = "";
              Password = "";
            };
            Datadir = "/var/lib/netbird";
            DataStoreEncryptionKey = "";
            HttpConfig = {
              Address = "0.0.0.0:33073";
              AuthIssuer = "https://netbird.brancen.world";
              AuthAudience = "netbird";
              AuthKeysLocation = "";
              AuthUserIDClaim = "";
              CertFile = "";
              KeyFile = "";
              OIDCConfigEndpoint = "";
              IdpSignKeyRefreshEnabled = false;
              HttpScheme = "https";
            };
            IdpManagerConfig = {};
            DeviceAuthorizationFlow = {};
            PKCEAuthorizationFlow = {};
          };
        }}:/etc/netbird/management.json:ro"
      ];
      environment = {
        NETBIRD_STORE_ENGINE_POSTGRES_DSN = "postgres://netbird:$POSTGRES_PASSWORD@host.containers.internal:${toString cfg.postgresPort}/netbird?sslmode=disable";
        NETBIRD_STORE_ENGINE = "postgres";
        NETBIRD_MGMT_PORT = toString cfg.managementPort;
        NETBIRD_MGMT_API_PORT = toString cfg.dashboardPort;
        NETBIRD_MGMT_API_CERT_FILE = "";
        NETBIRD_MGMT_API_KEY_FILE = "";
        NETBIRD_MGMT_API_AUTH_USER_ID_CLAIM = "";
        NETBIRD_MGMT_API_AUTH_AUDIENCE = "netbird";
        NETBIRD_MGMT_API_AUTH_ISSUER = "https://netbird.brancen.world";
        NETBIRD_MGMT_API_AUTH_KEYS_LOCATION = "";
        NETBIRD_MGMT_API_AUTH_SUPPORTED_TYPES = "oidc";
        NETBIRD_MGMT_IDP_SIGN_KEY_REFRESH = "false";
      };
      extraOptions = [
        "--secret=netbird-postgres-password,type=env,target=POSTGRES_PASSWORD"
        "--secret=netbird-turn-password,type=env,target=TURN_PASSWORD"
        "--secret=netbird-jwt-secret,type=env,target=NETBIRD_MGMT_API_AUTH_KEYS_LOCATION"
        "--add-host=host.containers.internal:host-gateway"
        "--network=host"
      ];
    };

    # Netbird Signal Quadlet
    virtualisation.oci-containers.containers.netbird-signal = {
      image = "netbirdio/signal:latest";
      autoStart = true;
      ports = ["${toString cfg.signalPort}:10000"];
      volumes = [
        "${dataDir}/signal:/var/lib/netbird"
      ];
      environment = {
        NETBIRD_SIGNAL_PORT = toString cfg.signalPort;
      };
    };

    # Netbird Relay Quadlet
    virtualisation.oci-containers.containers.netbird-relay = {
      image = "netbirdio/relay:latest";
      autoStart = true;
      ports = [
        "${toString cfg.turnPort}:3478"
        "${toString cfg.turnPort}:3478/udp"
        "5349:5349"
        "5349:5349/udp"
        "10000:10000/udp"
      ];
      environment = {
        NB_LOG_LEVEL = "info";
        NB_LISTEN_ADDRESS = ":${toString cfg.turnPort}";
        NB_EXPOSED_ADDRESS = "turn:netbird.brancen.world:${toString cfg.turnPort}";
        NB_AUTH_SECRET = "$TURN_PASSWORD";
      };
      extraOptions = [
        "--secret=netbird-turn-password,type=env,target=TURN_PASSWORD"
      ];
    };

    # Netbird Client (native package, not container, for VPN access)
    services.netbird = mkIf cfg.client.enable {
      enable = true;
      package = pkgs.netbird;
    };

    # Client configuration
    systemd.services.netbird-client-setup = mkIf cfg.client.enable {
      description = "Setup Netbird client for capacitor";
      after = ["netbird.service" "podman-netbird-management.service"];
      wants = ["netbird.service" "podman-netbird-management.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "netbird-setup" ''
          # Wait for management to be ready
          sleep 10

          # Check if already connected
          if ! ${pkgs.netbird}/bin/netbird status | grep -q "Connected"; then
            echo "Connecting to Netbird management server..."
            ${pkgs.netbird}/bin/netbird up --management-url ${cfg.client.managementUrl} --admin-url https://${cfg.domain}
          fi
        '';
      };
    };

    # Firewall rules
    networking.firewall = {
      allowedTCPPorts = [
        cfg.managementPort # 33073 - Management API
        cfg.dashboardPort # 18765 - Dashboard (internal)
        cfg.signalPort # 10000 - Signal
        cfg.turnPort # 3478 - TURN
        5349 # TURNS
      ];
      allowedUDPPorts = [
        cfg.signalPort # 10000 - Signal
        cfg.turnPort # 3478 - TURN/STUN
        5349 # TURNS
        10000 # Relay
      ];
    };

    # IP forwarding for Netbird (use mkDefault to avoid conflict with WireGuard)
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = lib.mkDefault 1;
      "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;
    };
  };
}
