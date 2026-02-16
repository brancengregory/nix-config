# modules/services/ai.nix
# AI/LLM services: Ollama, Open WebUI
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.ai-stack;
in {
  options.services.ai-stack = {
    enable = mkEnableOption "AI/LLM stack (Ollama, Open WebUI)";

    ollama = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Ollama LLM server";
      };
      acceleration = mkOption {
        type = types.enum ["none" "rocm" "cuda"];
        default = "none";
        description = "GPU acceleration for Ollama";
      };
    };

    open-webui = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Open WebUI (web interface for LLMs)";
      };
    };

    modelsDir = mkOption {
      type = types.str;
      default = "/mnt/storage/critical/ollama";
      description = "Directory for Ollama models";
    };
  };

  config = mkIf cfg.enable {
    # Ollama
    services.ollama = mkIf cfg.ollama.enable {
      enable = true;
      listenAddress = "0.0.0.0:11434";
      acceleration = cfg.ollama.acceleration;
      home = cfg.modelsDir;
      openFirewall = true;
    };

    # Open WebUI - Port 8080 (changed from 3000 to avoid conflict with Grafana)
    virtualisation.oci-containers.containers.open-webui = mkIf cfg.open-webui.enable {
      image = "ghcr.io/open-webui/open-webui:main";
      autoStart = true;
      ports = ["8080:8080"];
      volumes = [
        "/var/lib/open-webui:/app/backend/data"
      ];
      environment = {
        OLLAMA_BASE_URL = "http://host.docker.internal:11434";
        WEBUI_SECRET_KEY = "changeme-in-production";
      };
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
      ];
    };

    # Create directories
    systemd.tmpfiles.rules = [
      "d ${cfg.modelsDir} 0755 ollama ollama -"
      "d /var/lib/open-webui 0755 root root -"
    ];

    # Ensure Ollama can access models directory
    users.users.ollama = {
      home = cfg.modelsDir;
      createHome = true;
    };

    # Firewall ports
    networking.firewall.allowedTCPPorts = [
      11434 # Ollama API
      8080 # Open WebUI (changed from 3000 to avoid conflict with Grafana)
    ];
  };
}
