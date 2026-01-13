{pkgs, ...}: {
  # Enable the KDE Plasma 6 Desktop Environment.
  services.desktopManager.plasma6.enable = true;

  # Install Firefox and some basic KDE tools
  environment.systemPackages = with pkgs; [
    kdePackages.kate
    kdePackages.kcalc
    kdePackages.gwenview
    firefox
  ];
}
