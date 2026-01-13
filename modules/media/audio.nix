{pkgs, ...}: {
  # --- Low Latency Audio Setup ---

  # Enable RealtimeKit for real-time scheduling priorities
  security.rtkit.enable = true;

  # Kernel Selection
  # ----------------
  # Standard Kernel (Default): Good balance, usually sufficient for PipeWire.
  # Zen Kernel: Optimized for desktop responsiveness and multimedia.
  boot.kernelPackages = pkgs.linuxPackages_zen;
  # Low-Latency Kernel: Strict audio priority, might impact power/other tasks.
  # boot.kernelPackages = pkgs.linuxPackages_lowlatency;

  # PipeWire configuration is already enabled in modules/os/nixos.nix,
  # but we ensure the necessary components for pro audio are present.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # JACK support is crucial for professional audio applications like Bitwig
    jack.enable = true;
  };

  # Configure limits for real-time audio
  security.pam.loginLimits = [
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

  users.users.brancengregory.extraGroups = ["audio"];

  # --- Pro Audio Software ---

  environment.systemPackages = with pkgs; [
    bitwig-studio
    pavucontrol # Audio control
    qjackctl # JACK control/patchbay (useful for routing)
    yabridge # For using Windows VSTs (optional but common)
    yabridgectl
  ];
}
