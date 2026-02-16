# modules/services/ollama.nix
# Ollama LLM server
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.ollama-server;
in {
  options.services.ollama-server = {
    enable = mkEnableOption "Ollama LLM server";

    acceleration = mkOption {
      type = types.enum ["none" "rocm" "cuda"];
      default = "none";
      description = "GPU acceleration for Ollama";
    };

    modelsDir = mkOption {
      type = types.str;
      default = "/mnt/storage/critical/ollama";
      description = "Directory for Ollama models";
    };
  };

  config = mkIf cfg.enable {
    # Ollama
    services.ollama = {
      enable = true;
      listenAddress = "0.0.0.0:11434";
      acceleration = cfg.acceleration;
      home = cfg.modelsDir;
      # Firewall managed by host (VPN-only)
    };

    # Create directories
    systemd.tmpfiles.rules = [
      "d ${cfg.modelsDir} 0755 ollama ollama -"
    ];

    # Ensure Ollama can access models directory
    users.users.ollama = {
      home = cfg.modelsDir;
      createHome = true;
    };
  };
}
