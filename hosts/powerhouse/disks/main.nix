# Disk configuration for powerhouse
# NixOS is installed on nvme1n1 (dedicated drive)
# nvme0n1 contains Windows with shared ESP

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            # Backup EFI partition for NixOS
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                # Password unlock at boot (no keyfile)
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"]; # Force overwrite
                  subvolumes = {
                    "@" = {
                      mountpoint = "/";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@var_log" = {
                      mountpoint = "/var/log";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "@swap" = {
                      mountpoint = "/.swapvol";
                      swap = {
                        swapfile.size = "16G";
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
  };
}
