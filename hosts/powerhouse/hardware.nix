# Hardware configuration for powerhouse
# AMD Ryzen 7 5800X 8-Core Processor
# NVIDIA GeForce RTX 3070 Ti
# 64GB RAM
# Dual NVMe drives (nvme0n1: Windows, nvme1n1: NixOS)

{config, pkgs, ...}: {
  # AMD CPU microcode updates
  hardware.cpu.amd.updateMicrocode = true;

  # Kernel modules for boot
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

  # All kernel modules
  boot.kernelModules = [
    "kvm-amd"
    "amdgpu"
  ];

  # Boot kernel parameters for AMD
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
  ];

  # Enable KVM for virtualization
  virtualisation.kvmgt.enable = true;

  # NOTE: File systems are handled by Disko in disks/main.nix
  # Do not define fileSystems here to avoid conflicts

  # Power management
  powerManagement.cpuFreqGovernor = "performance";
  
  # High-DPI console
  console.font = "latarcyrheb-sun32";
  console.keyMap = "us";

  # Hardware scan timestamp
  # This was generated from nixos-generate-config on the target hardware
  # Last updated: 2026-02-15
}
