{pkgs, ...}: {
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Graphical manager for Bluetooth
  services.blueman.enable = true;
}
