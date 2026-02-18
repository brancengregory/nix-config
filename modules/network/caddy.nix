# modules/network/caddy.nix
# Caddy reverse proxy with wildcard SSL via Porkbun DNS
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.caddy-proxy;
in {
  options.services.caddy-proxy = {
    enable = mkEnableOption "Caddy reverse proxy with wildcard SSL";

    domain = mkOption {
      type = types.str;
      default = "brancen.world";
      description = "Base domain for wildcard certificate";
    };

    porkbunCredentialsFile = mkOption {
      type = types.path;
      description = "Path to file containing Porkbun API credentials (PORKBUN_API_KEY and PORKBUN_SECRET_KEY)";
    };

    vpnOnly = mkOption {
      type = types.bool;
      default = true;
      description = "Restrict Caddy to VPN interfaces only (WireGuard + NetBird + localhost)";
    };

    services = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          subdomain = mkOption {
            type = types.str;
            description = "Subdomain for this service (e.g., 'netbird' for netbird.brancen.world)";
          };
          port = mkOption {
            type = types.port;
            description = "Local port to proxy to";
          };
          path = mkOption {
            type = types.str;
            default = "/";
            description = "Path prefix to match";
          };
          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = "Additional Caddy configuration for this vhost";
          };
        };
      });
      default = {};
      description = "Services to proxy";
    };
  };

  config = mkIf cfg.enable {
    # Install Caddy with latest Porkbun DNS plugin (v0.3.1)
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = ["github.com/caddy-dns/porkbun@v0.3.1"];
        hash = "sha256-R1ZqQ8drcBQIH7cLq9kEvdg9Ze3bKkT8IAFavldVeC0=";
      };

      # Global options
      globalConfig = ''
        auto_https disable_redirects
        ${optionalString cfg.vpnOnly ''
          # Bind to VPN interfaces only
          default_bind 10.0.0.1 127.0.0.1 ::1
        ''}
      '';

      # Virtual hosts configuration
      virtualHosts = let
        # Helper to create vhost config for a service
        mkVhost = _name: svc: {
          hostName = "${svc.subdomain}.${cfg.domain}";
          extraConfig = ''
            ${optionalString cfg.vpnOnly ''
              # Restrict to VPN networks only (WireGuard + NetBird + localhost)
              @not_vpn {
                not remote_ip 10.0.0.0/8 100.64.0.0/10 127.0.0.1 ::1
              }
              respond @not_vpn "Access denied - VPN required" 403
            ''}

            tls {
              dns porkbun {
                api_key {env.PORKBUN_API_KEY}
                api_secret_key {env.PORKBUN_SECRET_KEY}
              }
            }

            reverse_proxy localhost:${toString svc.port}

            ${svc.extraConfig}
          '';
        };
      in
        mapAttrs mkVhost cfg.services;
    };

    # Create environment file for Caddy with Porkbun credentials
    systemd.services.caddy.serviceConfig = {
      EnvironmentFile = cfg.porkbunCredentialsFile;
    };

    # Firewall: VPN-only access
    networking.firewall = {
      # Only allow 80/443 from localhost and VPN subnets
      extraCommands = optionalString cfg.vpnOnly ''
        # Allow from localhost
        iptables -A INPUT -p tcp --dport 80 -s 127.0.0.1 -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -s 127.0.0.1 -j ACCEPT
        iptables -A INPUT -p tcp --dport 80 -s ::1 -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -s ::1 -j ACCEPT

        # Allow from WireGuard subnet (10.0.0.0/8)
        iptables -A INPUT -p tcp --dport 80 -s 10.0.0.0/8 -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -s 10.0.0.0/8 -j ACCEPT

        # Allow from NetBird subnet (100.64.0.0/10)
        iptables -A INPUT -p tcp --dport 80 -s 100.64.0.0/10 -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -s 100.64.0.0/10 -j ACCEPT

        # Drop all other 80/443 traffic
        iptables -A INPUT -p tcp --dport 80 -j DROP
        iptables -A INPUT -p tcp --dport 443 -j DROP
      '';
    };
  };
}
