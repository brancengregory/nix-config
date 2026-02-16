# Hardware configuration for capacitor
# ASRock Z690 PG Riptide
# 12th Gen Intel Core i5-12600K
# 64GB RAM
# Intel UHD Graphics 770
# Storage: 1TB NVMe (boot) + 3x HDDs (vaults)
{
  config,
  pkgs,
  ...
}: {
  # Intel CPU microcode updates
  hardware.cpu.intel.updateMicrocode = true;

  # Kernel modules for boot
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];

  # All kernel modules
  boot.kernelModules = [
    "kvm-intel"
    "i915" # Intel integrated graphics
    "r8169" # Realtek 2.5GbE NIC
  ];

  # Boot kernel parameters
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
  ];

  # Enable Intel integrated graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  # NOTE: LUKS configuration is handled by disko in disks.nix
  # Do not define boot.initrd.luks.devices here to avoid conflicts
  # The vault drives (sda, sdb, sdc) will be unlocked via /etc/crypttab

  # NOTE: File systems are handled by disko in disks.nix
  # Do not define fileSystems here to avoid conflicts

  # Power management for server
  powerManagement.cpuFreqGovernor = "performance";

  # Console settings
  console.font = "latarcyrheb-sun32";
  console.keyMap = "us";

  # Enable KVM for virtualization
  virtualisation.kvmgt.enable = true;

  # Hardware scan timestamp
  # Last updated: 2026-02-16
}
