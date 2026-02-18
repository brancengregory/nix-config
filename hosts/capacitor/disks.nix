# Disk configuration for capacitor
# Preserves existing LUKS-encrypted vaults and mergerfs setup
#
# Layout:
# - nvme0n1: 1TB NVMe (boot drive, LUKS encrypted, btrfs)
# - sda: 19TB HDD (LUKS encrypted, btrfs, vault1)
# - sdb: 11TB HDD (LUKS encrypted, btrfs, vault2)
# - sdc: 11TB HDD (LUKS encrypted, btrfs, vault3 - parity)
#
# MergerFS pools:
# - /mnt/storage/critical = vault1/critical + vault2/critical
# - /mnt/storage/standard = vault1/standard + vault2/standard
# - /mnt/storage/ephemeral = vault1/ephemeral + vault2/ephemeral
{...}: {
  # Boot drive (nvme0n1) - will be reformatted during install
  # This preserves the existing LUKS UUID and btrfs subvolumes
  disko.devices = {
    disk = {
      # Boot drive - nvme0n1
      boot = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
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
                name = "cryptnvme0n1p2";
                # Use existing UUID to preserve data
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"];
                  subvolumes = {
                    "@root" = {
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
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Existing LUKS vaults - these are preserved, not reformatted
  # They will be unlocked via /etc/crypttab or systemd-cryptsetup
  # The UUIDs are preserved from the current Arch setup

  # Vault 1 (sda) - 19TB
  # LUKS UUID: de63d2dc-d155-4020-9897-f8328bdf9ede
  # Btrfs UUID: d8a71f33-6597-429b-81e8-29705484dea4

  # Vault 2 (sdb) - 11TB
  # LUKS UUID: a8f9df1c-f7f2-49ad-985c-6f5b7117ebac
  # Btrfs UUID: 4d7b8196-0473-4463-8cff-fe8f7852e6c2

  # Vault 3 (sdc) - 11TB (parity)
  # LUKS UUID: 7e9cf71f-8db6-466a-b6de-757c7bc9baef
  # Btrfs UUID: 5c239a40-e1f1-462b-b1bb-3d5921b5c65c
}
