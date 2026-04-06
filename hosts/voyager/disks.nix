# Framework 16 Laptop - Disk Configuration
# Single 2TB NVMe with LUKS + Btrfs
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Disk configuration using disko
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # WD_BLACK SN850X 2TB
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };

            # LUKS encrypted root partition
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                  # Password unlock only for bootstrap
                  # TPM2 can be added later with:
                  # crypttab.extraEntries or systemd-cryptenroll
                };
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"]; # Force overwrite
                  subvolumes = {
                    # Root subvolume
                    "@" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd:1"
                        "noatime"
                      ];
                    };

                    # Home subvolume
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd:1"
                        "noatime"
                      ];
                    };

                    # Nix store subvolume
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd:1"
                        "noatime"
                      ];
                    };

                    # Logs subvolume
                    "@var_log" = {
                      mountpoint = "/var/log";
                      mountOptions = [
                        "compress=zstd:1"
                        "noatime"
                      ];
                    };

                    # Snapshots subvolume
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [
                        "compress=zstd:1"
                        "noatime"
                      ];
                    };

                    # Swap subvolume
                    "@swap" = {
                      mountpoint = "/.swap";
                      swap.swapfile.size = "16G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Boot loader configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Enable Btrfs support
    supportedFilesystems = ["btrfs"];

    # Kernel modules for LUKS
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "usb_storage"
      "sd_mod"
      "rtsx_pci_sdmmc"
    ];

    initrd.kernelModules = ["dm-snapshot"];
  };
}
