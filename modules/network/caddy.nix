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
      '';

      # Virtual hosts configuration
      virtualHosts = let
        # Helper to create vhost config for a service
        mkVhost = name: svc: {
          hostName = "${svc.subdomain}.${cfg.domain}";
          extraConfig = ''
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
      in mapAttrs mkVhost cfg.services;
    };

    # Create environment file for Caddy with Porkbun credentials
    systemd.services.caddy.serviceConfig = {
      EnvironmentFile = cfg.porkbunCredentialsFile;
    };

    # Open firewall for HTTP/HTTPS
    networking.firewall.allowedTCPPorts = [80 443];
  };
}
