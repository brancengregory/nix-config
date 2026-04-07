# Deployment Guide

**Complete procedures for deploying new hosts with hardware key authentication**

This guide covers the staged deployment model for new NixOS and macOS hosts using hardware tokens for authentication.

---

## Overview

### Deployment Model

We use a **staged pre-generation** approach to solve the bootstrap paradox:

1. **Weeks Before:** Generate age keys, store in Bitwarden, add to `.sops.yaml`
2. **Build Time:** Inject age key into ISO/installer
3. **Deploy:** System boots with SOPS access
4. **Post-Deploy:** Manual GPG provisioning with hardware token

### Security Principles

- **Manual Provisioning:** No automated scripts - fully documented manual steps
- **Hardware Token First:** All user auth flows through Nitrokey
- **Staged Secrets:** Pre-stage credentials in Bitwarden for deployment
- **Defense in Depth:** SSH host keys protect against server impersonation

---

## Pre-Deployment Phase (Weeks Before)

### Step 1: Generate Age Keys

**Environment:** Secure air-gapped machine (or Tails)

```bash
# Generate age keypair for new host
nix run nixpkgs#age -- -o battery-age.key

# Output shows:
# Public key: age1y03d2fe2vpej9ewd44uj7qvt7g9zekydj2rts0urjdyv7vpf6saq7kfvx3
# Private key saved to: battery-age.key
```

**Record in Documentation:**
- Hostname: `battery`
- Public Key: `age1y03d2fe2vpej9ewd44uj7qvt7g9zekydj2rts0urjdyv7vpf6saq7kfvx3`
- Generated: `2026-03-04`

### Step 2: Store in Bitwarden

**Item Type:** Secure Note  
**Name:** `Pre-staged Age Key - battery`

**Fields:**
```
Hostname: battery
Public Key: age1y03d2fe2vpej9ewd44uj7qvt7g9zekydj2rts0urjdyv7vpf6saq7kfvx3
Private Key: [copy entire contents of battery-age.key]
Status: Pre-staged
Created: 2026-03-04
Notes: For NixOS deployment. Keep until deployment confirmed.
```

**Security Note:** Private key is temporarily in Bitwarden only for deployment. Once deployed, it lives exclusively on the target host.

### Step 3: Add to .sops.yaml

```bash
# Edit .sops.yaml
vim .sops.yaml
```

**Add to recipients:**
```yaml
creation_rules:
  - path_regex: secrets/[^/]+\.yaml$
    key_groups:
      - age:
          # ... existing recipients ...
          - age1y03d2fe2vpej9ewd44uj7qvt7g9zekydj2rts0urjdyv7vpf6saq7kfvx3  # battery
```

**Commit:**
```bash
git add .sops.yaml
git commit -m "Add battery age key for deployment"
```

### Step 4: Re-encrypt Secrets

```bash
# Re-encrypt all secrets with new recipient
sops updatekeys secrets/secrets.yaml

# If you have other secret files
sops updatekeys secrets/netbird-secrets.yaml

# Commit
```
bash
git add secrets/*.yaml
git commit -m "Re-encrypt secrets for battery host"
```

### Step 5: Generate Host Secrets

**SSH Host Keys:**
```bash
# Generate for battery
ssh-keygen -t ed25519 -f /tmp/battery-ssh-host -N ""
# Produces: /tmp/battery-ssh-host (private) and /tmp/battery-ssh-host.pub (public)
```

**WireGuard Keys:**
```bash
# Generate WireGuard keypair
wg genkey | tee /tmp/battery-wg-private | wg pubkey > /tmp/battery-wg-public
```

**Age Key:** Already generated above

### Step 6: Update Secrets Template

Edit `secrets/secrets.template.yaml`:

```yaml
ssh:
    battery:
        host_key: |      # Content of /tmp/battery-ssh-host
          -----BEGIN OPENSSH PRIVATE KEY-----
          ...
        host_key_pub: |  # Content of /tmp/battery-ssh-host.pub
          ssh-ed25519 AAAAC3...

wireguard:
    battery:
        private_key: |   # Content of /tmp/battery-wg-private
        public_key: |    # Content of /tmp/battery-wg-public
        ip: 10.0.0.6     # Assign next available IP
        is_server: false

age:
    battery:
        public: age1y03d2fe2vpej9ewd44uj7qvt7g9zekydj2rts0urjdyv7vpf6saq7kfvx3
        private: |       # Content of battery-age.key
          # created: 2026-03-04
          # public key: age1y03d2fe2vpej9ewd44uj7qvt7g9zekydj2rts0urjdyv7vpf6saq7kfvx3
          AGE-SECRET-KEY-...
```

### Step 7: Encrypt and Commit

```bash
# Copy template to actual secrets file (if new)
cp secrets/secrets.template.yaml secrets/secrets.yaml

# Or update existing
sops secrets/secrets.yaml

# Edit and save (opens editor)

# Verify encryption
sops -d secrets/secrets.yaml | grep battery

# Commit
git add secrets/
git commit -m "Add battery host secrets (SSH, WireGuard, age)"
```

---

## Build Phase (Days Before)

### Step 1: Retrieve Age Key

```bash
# From Bitwarden, copy the private key for battery
# Save to temporary location (secure)
echo "AGE-SECRET-KEY-..." > /tmp/battery-age-key
```

### Step 2: Build NixOS Installer ISO

**For new NixOS host:**

```bash
# Build ISO with pre-injected age key
nix build .#nixosConfigurations.battery-iso.config.system.build.isoImage \
  --override-input age-key /tmp/battery-age-key
```

**ISO Configuration Requirements:**
- Include age private key in `/var/lib/sops/age/` or similar
- Enable sops-nix with proper key path
- Include basic network configuration

**Example ISO Configuration (`hosts/battery/iso.nix`):**
```nix
{ config, pkgs, ... }: {
  # Import base ISO configuration
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
  ];
  
  # SOPS configuration for ISO
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops/age/battery.txt";
    
    secrets = {
      # Only essential secrets for installation
      "wireguard/battery/private_key" = {};
      "ssh/battery/host_key" = {};
    };
  };
  
  # Pre-stage age key
  system.activationScripts.stage-age-key = {
    text = ''
      mkdir -p /var/lib/sops/age
      install -m 600 ${config.sops.secrets."age/battery/private".path} /var/lib/sops/age/battery.txt
    '';
  };
}
```

### Step 3: Build and Verify

```bash
# Build ISO
nix build .#battery-iso

# Verify contents (mount ISO and check)
# Ensure age key is present
# Ensure sops can decrypt
```

### Step 4: Create Boot Media

```bash
# Write ISO to USB
sudo dd if=result/iso/nixos-*.iso of=/dev/sdX bs=4M status=progress

# Or use modern tools
sudo nix run nixpkgs#disko -- --mode disko hosts/battery/disk-config.nix
```

---

## Deployment Day

### Step 1: Physical Installation

**Hardware Setup:**
```bash
# 1. Connect hardware
# - Ethernet cable (for network access)
# - USB drive with ISO
# - Keyboard/monitor (for initial setup)

# 2. Power on and boot from USB
# - Enter BIOS/UEFI boot menu
# - Select USB drive

# 3. Boot into NixOS installer
```

### Step 2: Network Verification

**Check connectivity:**
```bash
# In installer shell
ping 1.1.1.1
ip addr show

# Should get IP via DHCP or static config
```

### Step 3: Run Installation

**Standard NixOS install:**
```bash
# Partition (if using disko)
disko --mode disko /iso/hosts/battery/disk-config.nix

# Or manual partitioning
fdisk /dev/nvme0n1
mkfs.ext4 /dev/nvme0n1p1
mount /dev/nvme0n1p1 /mnt

# Generate config
nixos-generate-config --root /mnt

# Copy configuration
mkdir -p /mnt/etc/nixos
# Copy your flake to /mnt/etc/nixos/

# Install
nixos-install --flake /mnt/etc/nixos#battery

# Reboot
reboot
```

### Step 4: Post-Boot Verification

**System boots successfully:**
```bash
# 1. Check system is running
systemctl status

# 2. Verify SOPS is working
sops -d /var/run/secrets/secrets.yaml | head

# 3. Check WireGuard connection
wg show
ping 10.0.0.1  # Should reach capacitor

# 4. Verify SSH host keys
ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
# Should match what was in SOPS
```

---

## Post-Deployment Phase

### Step 1: Hardware Token Provisioning

**This is the critical step that enables GPG/SSH auth:**

```bash
# 1. Insert Nitrokey into new host

# 2. Fetch public key from keyserver
gpg --card-edit
# gpg/card> fetch
# gpg/card> quit

# 3. Create stubs by linking hardware
gpg-connect-agent "scd serialno" "learn --force" /bye

# 4. Verify stubs created
gpg --list-secret-keys
# Should show 'ssb>' notation for subkeys

# 5. Verify SSH key available
ssh-add -L | grep "cardno"
# Should show: ssh-ed25519 AAAAC3... cardno:000F_XXXXXXXX
```

### Step 2: Git Signing Verification

```bash
# Configure git (if not in home-manager yet)
git config --global user.name "Brancen Gregory"
git config --global user.email "brancengregory@gmail.com"
git config --global user.signingkey 3D9E0666449B886D

# Test signing
git init /tmp/test-repo
cd /tmp/test-repo
echo "test" > test.txt
git add .
git commit -m "Test hardware key signing"

# Verify signature
git log --show-signature -1
# Should show: Good signature from "Brancen Gregory"
```

### Step 3: SSH Authentication Verification

```bash
# Test GitHub SSH
ssh git@github.com

# Expected output:
# Hi brancengregory! You've successfully authenticated...

# Test with touch confirmation
# LED should blink, press token, auth succeeds
```

### Step 4: Access from Other Hosts

**From powerhouse:**
```bash
# SSH to new host
ssh brancengregory@battery.local

# Or via WireGuard IP
ssh brancengregory@10.0.0.6

# Should authenticate with hardware token
```

---

## Post-Deployment Cleanup

### Update Bitwarden

```bash
# Mark deployment complete
# In Bitwarden item "Pre-staged Age Key - battery":
# - Change Status from "Pre-staged" to "Deployed"
# - Add note: "System operational since 2026-03-04"
# - Private key now lives ONLY on battery host
```

### Update Documentation

```bash
# Add battery to infrastructure docs
# Update network diagrams
# Record serial numbers, IPs, etc.
```

### Verification Checklist

- [ ] System boots without USB
- [ ] SOPS decrypts secrets correctly
- [ ] WireGuard connects to mesh
- [ ] SSH host key matches SOPS
- [ ] Hardware token creates stubs
- [ ] Git signing works
- [ ] SSH to GitHub works
- [ ] SSH from other hosts works
- [ ] Bitwarden marked as deployed

---

## macOS Deployment (Turbine-style)

### Differences from NixOS

1. **No ISO:** Manual Nix installation
2. **Home-manager only:** No system-level config
3. **Age key generation on-device:** Can't pre-inject

### Procedure

**Step 1: Install Nix**
```bash
# Install Nix package manager
sh <(curl -L https://nixos.org/nix/install)

# Enable flakes
mkdir -p ~/.config/nix
experimental-features = nix-command flakes
EOF
```

**Step 2: Generate Age Key**
```bash
# On the new Mac
nix run nixpkgs#age -- -o ~/new-mac-age.key

# Record public key
age-keygen -y ~/new-mac-age.key
```

**Step 3: Add to .sops.yaml**
```bash
# On secure build machine
# Add new public key to .sops.yaml
# Re-encrypt secrets
# Push to git
```

**Step 4: Clone and Build**
```bash
# On new Mac
git clone https://github.com/brancengregory/nix-config.git
cd nix-config

# Copy age key to expected location
mkdir -p ~/.config/sops/age
cp ~/new-mac-age.key ~/.config/sops/age/keys.txt

# Build home-manager
nix run home-manager -- switch --flake .#brancengregory
```

**Step 5: Hardware Token Provisioning**
```bash
# Same as NixOS:
gpg --card-edit
# fetch
# quit

gpg-connect-agent "scd serialno" "learn --force" /bye

# Verify
ssh-add -L
git commit --allow-empty -m "Test"
```

---

## Emergency Procedures

### Deployment Failure

**Scenario:** Installation fails, need to retry

```bash
# 1. Retrieve age key from Bitwarden again
# 2. Debug ISO (mount and check)
# 3. Fix issues
# 4. Rebuild ISO with same age key
# 5. Retry deployment

# Key remains in Bitwarden until successful deployment
```

### Wrong Age Key

**Scenario:** Wrong key injected, can't decrypt SOPS

```bash
# 1. Verify correct key in Bitwarden
# 2. Check .sops.yaml has correct public key
# 3. Rebuild ISO with correct key
# 4. If system already installed, can add correct key:
#    - Manually copy to /var/lib/sops/age/
#    - Re-run sops-nix activation
```

### Hardware Token Not Available

**Scenario:** Need to deploy but forgot Nitrokey

**Options:**
1. **Defer GPG provisioning:** Deploy without GPG, provision later when token available
2. **Emergency access:** Use existing authorized_keys (if configured in SOPS)
3. **Abort and retry:** Wait until token available (recommended)

```bash
# Without hardware token, you can still:
# - SSH if authorized_keys is pre-configured
# - Access system via console
# - Provision GPG later: gpg --card-edit → fetch → learn
```

---

## Security Considerations

### Age Key Handling

**DO:**
- Generate on air-gapped machine
- Store temporarily in Bitwarden
- Delete from build machine after ISO creation
- Mark Bitwarden entry as "Deployed" after success

**DON'T:**
- Store age key in git (ever)
- Generate on build machine with network access
- Leave Bitwarden entry as "Pre-staged" indefinitely
- Share age private key

### ISO Security

**ISO contains:**
- Age private key (encrypted at rest)
- Basic network config
- SOPS with encrypted secrets

**Risks:**
- USB drive could be lost
- ISO could be copied

**Mitigation:**
- Use USB drive only for this deployment
- Destroy after successful install
- Age key is useless without SOPS secrets
- SOPS secrets are encrypted

### Post-Deployment

**Critical:**
- Verify hardware token provisioning works
- Remove any emergency access after token works
- Update all documentation
- Verify backup procedures

---

## Troubleshooting

### SOPS Won't Decrypt

**Symptom:** `sops -d` fails with age key error

**Solutions:**
```bash
# 1. Check age key exists
ls /var/lib/sops/age/
cat /var/lib/sops/age/battery.txt

# 2. Verify key matches .sops.yaml
age-keygen -y /var/lib/sops/age/battery.txt
# Compare to .sops.yaml

# 3. Check file permissions
chmod 600 /var/lib/sops/age/battery.txt

# 4. Manual test
sops -d --age $(age-keygen -y /var/lib/sops/age/battery.txt) secrets/secrets.yaml
```

### WireGuard Won't Connect

**Symptom:** No VPN connectivity

**Solutions:**
```bash
# 1. Check keys are correct
wg showconf wg0

# 2. Verify with capacitor
curl https://capacitor.local:51820/health

# 3. Check firewall
sudo iptables -L | grep 51820
```

### Hardware Token Not Creating Stubs

**Symptom:** `gpg --list-secret-keys` shows no stubs

**Solutions:**
```bash
# 1. Verify token detected
gpg --card-status

# 2. Fetch public key first
gpg --card-edit
# fetch
# quit

# 3. Force stub creation
gpg-connect-agent "scd serialno" "learn --force" /bye

# 4. Check scdaemon
gpgconf --check-programs
```

---

## Quick Reference

### Pre-Deployment Commands

```bash
# Generate age key
nix run nixpkgs#age -- -o HOSTNAME-age.key

# Store in Bitwarden (manual)
# Add to .sops.yaml (manual)

# Re-encrypt
sops updatekeys secrets/secrets.yaml
```

### Build Commands

```bash
# Build ISO
nix build .#nixosConfigurations.HOSTNAME-iso.config.system.build.isoImage

# Write to USB
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress
```

### Post-Deployment Commands

```bash
# Hardware token provisioning
gpg --card-edit
# fetch
# quit

gpg-connect-agent "scd serialno" "learn --force" /bye

# Verify
ssh-add -L
gpg --list-secret-keys
git commit --allow-empty -m "Test"
```

---

## Related Documentation

- **Hardware Tokens:** `docs/HARDWARE-KEYS.md` - Daily operation
- **GPG/SSH Strategy:** `docs/GPG-SSH-STRATEGY.md` - Complete workflow
- **Secret Management:** `docs/SECRET_MANAGEMENT.md` - SOPS details
- **Security Guidelines:** `docs/SECURITY.md` - Threat model
- **Public Key:** `keys/brancen-gregory-public.asc` - Local backup

---

*Last Updated: 2026-03-04*
