# Voyager - Framework 16 Laptop

A high-performance, fully customizable laptop powered by AMD's Ryzen AI 300 Series processor.

## Hardware Specifications

| Component | Specification |
|-----------|---------------|
| **CPU** | AMD Ryzen AI 9 HX 370 (12-core/24-thread, up to 5.1GHz) |
| **Architecture** | Zen 5 + RDNA 3.5 (Radeon 890M iGPU) |
| **NPU** | AMD XDNA 2 (50 TOPS AI performance) |
| **Storage** | WD_BLACK SN850X NVMe M.2 2280 - 2TB |
| **Expansion Bay** | Expansion Bay Shell (no dGPU currently) |
| **Power Adapter** | 240W USB-C (USB-PD 3.1 / EPR) |
| **Display** | 16" 2560×1600, 165Hz, 100% DCI-P3, 500 nits |
| **Memory** | DDR5-5600 SO-DIMM (upgradeable, up to 96GB) |
| **Networking** | AMD RZ717 WiFi 7 + Bluetooth 5.4 |
| **Security** | Fingerprint reader, Webcam/Mic hardware switches |

## Features

- **Modular Design**: Hot-swappable input modules, expansion bay, and expansion cards
- **Repairable**: All components accessible with a single screwdriver
- **Linux Native**: First-class NixOS support via nixos-hardware
- **Open Source**: QMK keyboard firmware, open hardware documentation

## Configuration

### Bootstrap Mode (Initial Installation)

This configuration starts in "bootstrap mode" with minimal dependencies:

- ✅ No sops-nix (secrets management)
- ✅ No WireGuard VPN
- ✅ No declarative SSH host keys
- ✅ Password-based LUKS unlock
- ✅ Basic Plasma desktop

### Phase 2 (After Bootstrap)

After successful installation:

1. Extract SSH host key from the installed system
2. Generate age key using `ssh-to-age`
3. Add age public key to `.sops.yaml`
4. Enable sops-nix in configuration
5. Add WireGuard and other secret-dependent modules
6. Optionally: Enable TPM2 for LUKS unlock

## Installation

### Prerequisites

1. **NixOS Installer**: Boot from NixOS ISO or use nix-anywhere from existing Linux
2. **Network Access**: Internet connection for fetching packages
3. **SSH Access**: For remote installation (optional)

### Using nix-anywhere (Recommended)

From a machine with this flake:

```bash
# Build the configuration
nix build .#voyager

# Install via nix-anywhere (run on target machine or via SSH)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#voyager \
  --target-host root@voyager-ip \
  --disko-mode destroy
```

### Manual Installation

From the NixOS installer:

```bash
# Partition and format disks
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode destroy --mode zap_create_mount ./hosts/voyager/disks.nix

# Install NixOS
sudo nixos-install --flake .#voyager

# Reboot
reboot
```

## Post-Installation Steps

### 1. Extract SSH Host Key

After first boot, extract the host's SSH key:

```bash
# From the new system
sudo cat /etc/ssh/ssh_host_ed25519_key.pub

# Or from another machine
ssh-keyscan -t ed25519 voyager.local | grep -v '^#'
```

### 2. Generate Age Key

```bash
# Convert SSH host key to age key
ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key > /etc/ssh/ssh_host_ed25519_key.age

# Or get the public key for sops
ssh-keyscan -t ed25519 voyager.local | ssh-to-age
```

### 3. Update SOPS Configuration

Add voyager's age public key to `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: secrets/.*
    key_groups:
      - age:
          - "age1..." # existing keys
          - "age1..." # voyager's key
```

### 4. Rebuild with Secrets

Update `flake.nix` to use `lib.mkHost` with sopsModule, then:

```bash
# Update secrets file with new key
sops updatekeys secrets/secrets.yaml

# Add WireGuard config to secrets
# Edit secrets/secrets.yaml to add voyager's WireGuard keys

# Rebuild with full configuration
sudo nixos-rebuild switch --flake .#voyager
```

### 5. Optional: Enable TPM2 for LUKS

After bootstrap, you can enroll TPM2 for automatic LUKS unlock:

```bash
# Check TPM2 availability
tpm2_getcap properties-fixed

# Enroll TPM2 with systemd-cryptenroll
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2

# Or with password fallback
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 --wipe-slot=empty /dev/nvme0n1p2
```

Update `disks.nix` to use TPM2 token:

```nix
content = {
  type = "luks";
  name = "cryptroot";
  settings = {
    allowDiscards = true;
    # For TPM2 unlock
    crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-pcrs=0+7" ];
  };
  # ... rest of config
};
```

## Hardware Support

This configuration uses `nixos-hardware.nixosModules.framework-16-amd-ai-300-series` which provides:

- **Kernel**: 6.14+ (minimum required for Ryzen AI 300 series)
- **Graphics**: AMD GPU stability mitigations
  - `amdgpu.dcdebugmask=0x410`
  - `amdgpu.sg_display=0`
  - `amdgpu.abmlevel=0`
- **Firmware**: fwupd for UEFI/firmware updates
- **Input**: QMK keyboard support, fingerprint reader (fprintd)
- **Display**: High-DPI settings, brightness control
- **Networking**: WiFi 7 (RZ717) and Bluetooth 5.4 support

## Maintenance

### Firmware Updates

```bash
# Check for available updates
fwupdmgr refresh
fwupdmgr get-updates

# Install updates
fwupdmgr update
```

### Battery Optimization

```bash
# View power consumption
powertop

# Apply power saving settings
sudo tlp start
```

### Keyboard Customization

The Framework 16 uses QMK firmware for full keyboard programmability:

1. Visit https://keyboard.frame.work in a WebHID-compatible browser
2. Use the visual configurator to customize layouts
3. Flash directly from the browser

### Expansion Cards

The Framework 16 has 6 Expansion Card slots (3 per side). Cards can be hot-swapped:

- USB-C, USB-A, HDMI, DisplayPort
- Ethernet (2.5Gbps)
- MicroSD, SD
- Audio (3.5mm)
- Storage (250GB, 1TB)

## Troubleshooting

### Display Issues

If experiencing white screens or flickering, the nixos-hardware module applies necessary kernel parameters automatically. Check with:

```bash
cat /proc/cmdline | grep amdgpu
```

### WiFi Issues

For WiFi 7 (802.11be) support, ensure you're using a compatible access point:

```bash
iw phy | grep -i "802.11be\|eht"
```

### Suspend/Resume

For best suspend/resume behavior:

```bash
# Check current sleep state
cat /sys/power/mem_sleep

# Deep sleep should be available
echo deep | sudo tee /sys/power/mem_sleep
```

## References

- [Framework Laptop 16](https://frame.work/products/laptop16)
- [NixOS Hardware - Framework 16](https://github.com/NixOS/nixos-hardware/tree/master/framework/16-inch/amd-ai-300-series)
- [Framework Linux Support](https://frame.work/linux)
- [Framework GitHub](https://github.com/FrameworkComputer)
- [NixOS Wiki - Framework](https://wiki.nixos.org/wiki/Framework)

## Notes

- The Ryzen AI 9 HX 370 requires kernel 6.14+ for full functionality
- GPU is integrated RDNA 3.5 (Radeon 890M) - no dGPU in Expansion Bay Shell config
- NPU (XDNA 2) is available for AI workloads but requires specific software support
- Battery capacity is 85Wh, designed for 80% capacity retention at 1,000 cycles
