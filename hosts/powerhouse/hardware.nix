{...}: {
  # Hardware configuration for powerhouse
  # Note: Real hardware scan (nixos-generate-config) should replace specific kernel modules here later.

  # Bootloader - Use systemd-boot for UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
