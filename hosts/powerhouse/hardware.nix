{...}: {
  # Minimal hardware configuration for powerhouse
  # This provides the required fileSystems and boot options

  # Root filesystem configuration - minimal for VM/testing
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Boot configuration - using GRUB as required by the error message
  boot.loader.grub = {
    enable = true;
    devices = ["/dev/sda"]; # This satisfies the boot.loader.grub.devices requirement
  };
}
