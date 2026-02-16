# modules/services/openwebui.nix
# Open WebUI - web interface for LLMs
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.open-webui;
in {
  options.services.open-webui = {
    enable = mkEnableOption "Open WebUI (web interface for LLMs)";

    ollamaUrl = mkOption {
      type = types.str;
      default = "http://host.docker.internal:11434";
      description = "URL for Ollama API";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for Open WebUI (changed from 3000 to avoid conflict with Grafana)";
    };
  };

  config = mkIf cfg.enable {
    # Open WebUI container
    virtualisation.oci-containers.containers.open-webui = {
      image = "ghcr.io/open-webui/open-webui:main";
      autoStart = true;
      ports = ["${toString cfg.port}:${toString cfg.port}"];
      volumes = [
        "/var/lib/open-webui:/app/backend/data"
      ];
      environment = {
        OLLAMA_BASE_URL = cfg.ollamaUrl;
        WEBUI_SECRET_KEY = "changeme-in-production";
      };
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
      ];
    };

    # Create directories
    systemd.tmpfiles.rules = [
      "d /var/lib/open-webui 0755 root root -"
    ];

    # Firewall managed by host (VPN-only)
  };
}
