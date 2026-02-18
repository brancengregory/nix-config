{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.media.audio;
in {
  options.media.audio = {
    enable = mkEnableOption "PipeWire audio subsystem";

    lowLatency = mkEnableOption "low-latency audio with Zen kernel (WARNING: changes kernel)";

    proAudio = mkEnableOption "pro audio configuration (JACK, real-time limits, Bitwig Studio)";

    server = mkOption {
      type = types.enum ["pipewire" "pulse" "alsa" "none"];
      default = "pipewire";
      description = "Audio server implementation";
    };

    user = mkOption {
      type = types.str;
      default = "brancengregory";
      description = "User to add to audio group";
    };
  };

  config = mkIf cfg.enable {
    # Real-time scheduling for audio
    security.rtkit.enable = true;

    # Audio server configuration
    services.pipewire = mkIf (cfg.server == "pipewire") {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = cfg.proAudio;
    };

    services.pulseaudio.enable = mkIf (cfg.server == "pulse") true;

    # Low-latency kernel switch - ONLY if explicitly requested
    boot.kernelPackages = mkIf cfg.lowLatency pkgs.linuxPackages_zen;

    # Pro audio configuration
    security.pam.loginLimits = mkIf cfg.proAudio [
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "99";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "soft";
        value = "99999";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "hard";
        value = "99999";
      }
    ];

    users.users.${cfg.user}.extraGroups = ["audio"];

    # Pro audio software
    environment.systemPackages = mkIf cfg.proAudio (with pkgs; [
      bitwig-studio
      pavucontrol
      qjackctl
      yabridge
      yabridgectl
    ]);
  };
}
