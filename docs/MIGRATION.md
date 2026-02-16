# NixOS Migration Guide: Arch Linux to NixOS

This guide documents the migration from Arch Linux to NixOS on powerhouse, with Windows dual-boot.

## Overview

- **Source System**: Arch Linux with LVM+LUKS on 2x 1.8TB NVMe drives
- **Target System**: NixOS with LUKS+Btrfs on nvme1n1, Windows on nvme0n1
- **Dual-boot**: systemd-boot with Windows chainloading
- **Backup Strategy**: Restic to Google Cloud Storage (pre-requisite)

## Pre-Migration Checklist

### 1. Backup Current System

Before proceeding, ensure complete backups:

```bash
# Verify restic backup is up to date
restic -r gs:powerhouse-backup:/ snapshots

# Run fresh backup
restic -r gs:powerhouse-backup:/ backup /home/brancengregory \
  --exclude="/home/brancengregory/.cache" \
  --exclude="/home/brancengregory/Downloads" \
  --exclude="/home/brancengregory/.local/share/Trash"

# Verify backup integrity
restic -r gs:powerhouse-backup:/ check
```

### 2. Export Configuration Data

```bash
# Create export directory
mkdir -p ~/migration-exports

# SSH keys
cp -r ~/.ssh ~/migration-exports/

# GPG keys
gpg --export-secret-keys --armor > ~/migration-exports/gpg-private-keys.asc
gpg --export --armor > ~/migration-exports/gpg-public-keys.asc

# Browser profiles (bookmarks, extensions, etc.)
# Firefox
cp -r ~/.mozilla ~/migration-exports/ 2>/dev/null || true

# Chrome/Chromium
cp -r ~/.config/google-chrome ~/migration-exports/ 2>/dev/null || true
cp -r ~/.config/chromium ~/migration-exports/ 2>/dev/null || true

# Document any manually installed packages
pacman -Qe > ~/migration-exports/explicit-packages.txt
pacman -Qm > ~/migration-exports/aur-packages.txt

# Copy exports to external storage or restic backup
restic -r gs:powerhouse-backup:/ backup ~/migration-exports
```

### 3. Gather System Information

```bash
# Save current partition layout
lsblk -f > ~/migration-exports/lsblk-layout.txt
fdisk -l > ~/migration-exports/fdisk-layout.txt

# Save network configuration
ip addr > ~/migration-exports/network-config.txt
cat /etc/resolv.conf > ~/migration-exports/resolv.conf

# Save custom systemd services
ls -la /etc/systemd/system/ > ~/migration-exports/custom-services.txt

# Save cron jobs
crontab -l > ~/migration-exports/crontab.txt 2>/dev/null || true
sudo crontab -l > ~/migration-exports/root-crontab.txt 2>/dev/null || true
```

## Phase 1: Windows Installation

### 1.1 Prepare Windows Installation

1. Download Windows 11 ISO from Microsoft
2. Create bootable USB with Ventoy or Rufus
3. Backup Windows product key (if applicable)

### 1.2 Install Windows on nvme0n1

**Boot from Windows USB:**
1. Boot into Windows installer
2. Select "Custom: Install Windows only (advanced)"
3. **Important**: Only select nvme0n1 (Drive 0), NOT nvme1n1

**Partition Layout for nvme0n1:**
```
Disk 0 (nvme0n1) - 1.8TB
├── System Partition (100MB) - EFI
├── MSR (16MB)
├── Windows (1024GB) - C: drive
└── Unallocated (~780GB) - Future use
```

**Installation Steps:**
1. Delete all partitions on Disk 0
2. Select unallocated space, click "New"
3. Windows will create necessary partitions
4. Adjust C: drive to 1024000 MB (1TB)
5. Leave remaining ~780GB unallocated
6. Install Windows to the 1TB partition

### 1.3 Post-Windows Setup

1. Complete Windows setup (skip Microsoft account if desired)
2. Install drivers (GPU, chipset, etc.)
3. Enable BitLocker if desired (on Windows drive only)
4. **IMPORTANT**: Note the PARTUUID of the Windows ESP partition

```powershell
# In Windows PowerShell (Admin)
diskpart
list disk
select disk 0
list partition
select partition 1  # Usually the EFI partition
detail partition
# Note the "Partition UUID" value
```

## Phase 2: NixOS Installation Preparation

### 2.1 Generate SSH Host Key

Before installation, generate the powerhouse SSH host key:

```bash
# On your current Arch system or another Linux machine
mkdir -p ~/powerhouse-ssh-key
cd ~/powerhouse-ssh-key

# Generate host key
ssh-keygen -t ed25519 -f ssh_host_ed25519_key -N "" -C "powerhouse-host-key"

# The files will be:
# - ssh_host_ed25519_key (private)
# - ssh_host_ed25519_key.pub (public)
```

### 2.2 Add SSH Key to Secrets

```bash
# Copy public key to this repo's secrets directory
cp ~/powerhouse-ssh-key/ssh_host_ed25519_key.pub /path/to/nix-config/secrets/powerhouse_host_key.pub

# Add private key to secrets.yaml using sops
cd /path/to/nix-config

# Edit secrets.yaml
sops secrets/secrets.yaml

# Add new entries:
# ssh:
#   host_key: |
#     -----BEGIN OPENSSH PRIVATE KEY-----
#     ... (paste contents of ssh_host_ed25519_key)
#     -----END OPENSSH PRIVATE KEY-----
#   host_key_pub: ssh-ed25519 AAAAC3NzaC... brancengregory@powerhouse
```

### 2.3 Update Configuration

Update the Windows ESP PARTUUID in `hosts/powerhouse/config.nix`:

```nix
fileSystems."/boot/efi-windows" = {
  device = "/dev/disk/by-partuuid/XXXX-XXXX";  # Replace with actual PARTUUID
  fsType = "vfat";
  options = ["noauto" "x-systemd.automount"];
};
```

### 2.4 Build NixOS Installer

Create a custom NixOS installer with your flake:

```bash
cd /path/to/nix-config

# Build the installer ISO
nix build .#nixosConfigurations.powerhouse.config.system.build.isoImage

# Or download standard NixOS ISO and use manually
```

## Phase 3: NixOS Installation

### 3.1 Boot NixOS Installer

1. Boot from NixOS USB
2. Select "NixOS Installer" from boot menu
3. Connect to internet (WiFi or Ethernet)

### 3.2 Prepare Installation Environment

```bash
# Set up networking (if WiFi)
nmtui

# Clone your flake (or use local copy)
git clone https://github.com/brancengregory/nix-config.git /mnt/nix-config
cd /mnt/nix-config

# Or copy from USB/mounted drive
cp -r /path/to/nix-config /mnt/
```

### 3.3 Run Disko Partitioning

**WARNING**: This will DESTROY all data on nvme1n1!

```bash
cd /mnt/nix-config

# Dry run first to verify layout
sudo nix run github:nix-community/disko -- --mode disko hosts/powerhouse/disks/main.nix --dry-run

# If layout looks correct, run for real
sudo nix run github:nix-community/disko -- --mode disko hosts/powerhouse/disks/main.nix

# Verify partitions
lsblk
```

### 3.4 Generate Hardware Configuration

```bash
# Mount the new root
sudo mount /dev/mapper/crypted /mnt
sudo mount /dev/nvme1n1p1 /mnt/boot

# Generate hardware config
sudo nixos-generate-config --root /mnt

# Copy generated hardware config to your flake
cp /mnt/etc/nixos/hardware-configuration.nix hosts/powerhouse/hardware-generated.nix

# Compare with existing and merge any new modules
# Then update hardware.nix if needed
```

### 3.5 Install NixOS

```bash
# Install NixOS with your flake
sudo nixos-install --flake .#powerhouse

# Set root password
sudo passwd

# Reboot
sudo reboot
```

## Phase 4: Post-Installation

### 4.1 Initial Setup

After first boot:

```bash
# Set user password
sudo passwd brancengregory

# Verify boot entries
sudo bootctl list

# Check all filesystems are mounted correctly
df -h
lsblk
```

### 4.2 Configure Bootloader for Windows

If Windows doesn't appear in boot menu:

```bash
# Mount Windows ESP
sudo mkdir -p /boot/efi-windows
sudo mount /dev/nvme0n1p1 /boot/efi-windows  # Adjust partition number

# Copy Windows bootloader
sudo mkdir -p /boot/EFI/Microsoft/Boot
sudo cp -r /boot/efi-windows/EFI/Microsoft/Boot/* /boot/EFI/Microsoft/Boot/

# Update systemd-boot
sudo bootctl update

# Reboot and check
sudo reboot
```

### 4.3 Restore Data from Backup

```bash
# Install restic if not already present
# (should be in your home.nix)

# Restore home directory
restic -r gs:powerhouse-backup:/ restore latest --target /tmp/restore --include "/home/brancengregory"

# Copy files to proper location
sudo cp -r /tmp/restore/home/brancengregory/* /home/brancengregory/
sudo chown -R brancengregory:users /home/brancengregory

# Restore migration exports
restic -r gs:powerhouse-backup:/ restore latest --target /tmp/migration --include "/migration-exports"
```

### 4.4 Restore SSH and GPG Keys

```bash
# Restore SSH keys
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp /tmp/migration/migration-exports/.ssh/* ~/.ssh/
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub 2>/dev/null || true

# Restore GPG keys
gpg --import /tmp/migration/migration-exports/gpg-public-keys.asc
gpg --import /tmp/migration/migration-exports/gpg-private-keys.asc

# Trust keys (if needed)
gpg --edit-key <KEY_ID>
# Type: trust
# Select trust level: 5 (ultimate)
# Save
```

### 4.5 Verify Configuration

```bash
# Check snapper is working
snapper list
snapper list --config home

# Verify NVIDIA drivers
nvidia-smi

# Check Btrfs subvolumes
sudo btrfs subvolume list /

# Verify swap
swapon -s
free -h

# Test boot entries
sudo bootctl list
```

## Phase 5: Final Configuration

### 5.1 Update Flake with Real Hardware Config

After installation, update the repository:

```bash
cd ~/nix-config  # or wherever you cloned it

# Update hardware.nix with any changes from install
# Update secrets with powerhouse SSH host key
# Commit changes
git add .
git commit -m "Update powerhouse config after installation"
git push
```

### 5.2 Enable Automatic Backups

Ensure restic backup service is working:

```bash
# Check service status
systemctl status restic-backups-daily-home

# Test backup manually
sudo systemctl start restic-backups-daily-home
sudo journalctl -u restic-backups-daily-home -f

# Verify backup in cloud
restic -r gs:powerhouse-backup:/ snapshots
```

## Troubleshooting

### Windows Not Showing in Boot Menu

```bash
# Manually add Windows entry
sudo mkdir -p /boot/loader/entries

sudo tee /boot/loader/entries/windows.conf <<EOF
title Windows 11
efi /EFI/Microsoft/Boot/bootmgfw.efi
EOF

# Or copy bootloader files
sudo mkdir -p /boot/EFI/Microsoft/Boot
sudo cp /boot/efi-windows/EFI/Microsoft/Boot/bootmgfw.efi /boot/EFI/Microsoft/Boot/
sudo cp /boot/efi-windows/EFI/Microsoft/Boot/*.efi /boot/EFI/Microsoft/Boot/
```

### LUKS Boot Issues

If system doesn't prompt for LUKS password:

```bash
# From NixOS installer, chroot into system
sudo mount /dev/mapper/crypted /mnt
sudo mount /dev/nvme1n1p1 /mnt/boot
sudo nixos-enter

# Check initrd configuration
cat /etc/nixos/configuration.nix | grep -A5 "initrd"

# Ensure cryptd is in initrd
boot.initrd.luks.devices."crypted".device = "/dev/disk/by-uuid/...";
```

### NVIDIA Driver Issues

If graphical session fails to start:

```bash
# Boot to multi-user.target (no GUI)
systemctl isolate multi-user.target

# Check NVIDIA module
modinfo nvidia

# Check X11 logs
journalctl -u display-manager -b

# Try disabling modesetting temporarily
# Edit config to set: hardware.nvidia.modesetting.enable = false;
```

### BTRFS Subvolume Issues

```bash
# Check subvolumes
sudo btrfs subvolume list /

# If @home not mounted correctly
sudo umount /home
sudo mount -o subvol=@home,compress=zstd,noatime /dev/mapper/crypted /home

# Update /etc/fstab or fix in configuration.nix
```

## Rollback Plan

If migration fails catastrophically:

1. Boot Arch Linux live USB
2. Unlock LUKS volumes:
   ```bash
   cryptsetup open /dev/nvme0n1p2 cryptkeeper
   ```
3. Mount and access data
4. Restore from restic backup if needed
5. Reinstall GRUB if needed:
   ```bash
   mount /dev/mapper/cryptkeeper-root /mnt
   mount /dev/nvme0n1p1 /mnt/boot
   arch-chroot /mnt
   grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
   grub-mkconfig -o /boot/grub/grub.cfg
   ```

## Post-Migration Checklist

- [ ] System boots successfully
- [ ] Windows boots from systemd-boot menu
- [ ] LUKS password prompt works
- [ ] All Btrfs subvolumes mounted correctly
- [ ] NVIDIA drivers loaded
- [ ] Plasma desktop starts
- [ ] Snapper snapshots working (test: `snapper create -d "test"`)
- [ ] Home directory restored with correct permissions
- [ ] SSH keys working (test: `ssh -T git@github.com`)
- [ ] GPG keys restored (test: `gpg --list-secret-keys`)
- [ ] Restic backup configured and tested
- [ ] All critical applications installed and working
- [ ] Firefox/Chrome profiles restored
- [ ] Network configuration working (WiFi, VPN, etc.)
- [ ] Printer/scanner working (if applicable)
- [ ] Bluetooth devices paired

## Notes

- Keep Arch installation USB accessible during first week
- Monitor disk usage on new Btrfs layout: `btrfs filesystem df /`
- Test snapper rollback: `sudo snapper rollback`
- Document any manual tweaks needed after install
- Update this guide with lessons learned

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Disko Documentation](https://github.com/nix-community/disko)
- [systemd-boot](https://systemd.io/BOOT_LOADER_SPECIFICATION/)
- [Btrfs Wiki](https://btrfs.wiki.kernel.org/)
- [Snapper Documentation](http://snapper.io/)
