# Framework 16 Laptop - Hardware Configuration
# AMD Ryzen AI 300 Series (Ryzen AI 9 HX 370)
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Most hardware configuration is handled by:
  # nixos-hardware.nixosModules.framework-16-amd-ai-300-series
  #
  # This includes:
  # - Kernel 6.14+ for Ryzen AI 300 series support
  # - AMD GPU stability mitigations
  # - Fingerprint reader (fprintd)
  # - Firmware updates (fwupd)
  # - QMK keyboard support
  # - High-DPI display settings
  # - AMD RZ717 WiFi 7 module support

  # Enable all firmware
  hardware.enableAllFirmware = true;

  # CPU microcode updates
  hardware.cpu.amd.updateMicrocode = true;

  # Graphics - handled by nixos-hardware, but ensure basics are set
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # For Steam/games if needed later
  };

  # Audio - handled by modules/os/nixos.nix
  # services.pipewire is already defined there

  # Platform-specific settings
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Power management
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
