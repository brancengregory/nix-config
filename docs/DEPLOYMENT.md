# Deployment Guide

**Deploying NixOS hosts using nix-anywhere and hardware tokens**

This guide covers the actual workflow used for deploying NixOS hosts, which differs significantly from the old pre-staged approach.

---

## Overview

### Actual Deployment Model

1. **Boot target machine** with standard NixOS ISO (from nixos.org)
2. **Run nix-anywhere** to remotely install the system
3. **SSH host key generated** automatically by nix-anywhere
4. **Convert SSH key to age** using ssh-to-age for sops-nix
5. **Provision GPG/SSH** by physically inserting Nitrokey

### Key Differences from Old Approach

| Aspect | Old (Documented) | Actual (Current) |
|--------|------------------|------------------|
| ISO | Custom-built with pre-staged keys | Standard NixOS ISO |
| Keys | Pre-generated, stored in Bitwarden | Generated during install by nix-anywhere |
| Age keys | Pre-staged | Derived from SSH host keys via ssh-to-age |
| Provisioning | Scripted | Manual with hardware token |

---

## Prerequisites

### On Your Workstation (where you run the commands)

```bash
# Install nix-anywhere
nix profile install nixpkgs#nixos-anywhere

# Ensure you have ssh-to-age
nix profile install nixpkgs#ssh-to-age

# Have your Nitrokey ready for post-install provisioning
```

### Target Machine

- Bootable from USB
- Network connectivity
- Physical access for Nitrokey insertion (post-install)

---

## Deployment Steps

### Step 1: Boot Target with NixOS ISO

1. Download standard NixOS ISO from https://nixos.org/download
2. Write to USB: `dd if=nixos.iso of=/dev/sdX bs=4M status=progress`
3. Boot target machine from USB
4. Note the IP address (displayed on boot or via `ip addr`)

### Step 2: Prepare SSH Access

From the NixOS live environment on the target:

```bash
# Set a temporary password for root
passwd
# Enter a temporary password

# Get the IP address
ip addr show
```

From your workstation:

```bash
# Copy your SSH key to the target for nix-anywhere
ssh-copy-id -o StrictHostKeyChecking=no root@<target-ip>

# Test connection
ssh root@<target-ip>
```

### Step 3: Run nix-anywhere

From your workstation:

```bash
cd /path/to/nix-config

# Install to target
nixos-anywhere --flake .#<hostname> root@<target-ip>

# Example:
# nixos-anywhere --flake .#voyager root@192.168.1.100
```

**What nix-anywhere does:**
- Partitions disk (via disko configuration)
- Installs NixOS with your flake configuration
- Generates SSH host keys
- Sets up basic system

### Step 4: Extract SSH Host Key for SOPS

After nix-anywhere completes, the target has generated SSH host keys. You need to extract the public key and convert it to age format:

```bash
# From your workstation, SSH into the new host
ssh root@<target-ip>

# On the target, show the SSH host public key
cat /etc/ssh/ssh_host_ed25519_key.pub
# Copy this key (starts with ssh-ed25519 AA...)
```

Back on your workstation:

```bash
# Convert SSH key to age format
ssh-to-age -i <path-to-ssh-key> -o <hostname>-age.key

# Get the public key
age-keygen -y <hostname>-age.key
# Copy this public key
```

### Step 5: Update .sops.yaml

Add the new host's age public key to `.sops.yaml`:

```yaml
keys:
  # ... existing keys ...
  - &host_<hostname> <age-public-key-from-above>

creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
      - age:
        - *user_core
        # ... other hosts ...
        - *host_<hostname>
```

### Step 6: Add Host to secrets.yaml

Now you can add secrets for this host that it can decrypt:

```bash
# Edit secrets with sops
sops secrets/secrets.yaml

# Add new host entries under appropriate sections, e.g.:
# wireguard:
#   <hostname>:
#     private_key: <generate with: wg genkey>
#     public_key: <echo <private> | wg pubkey>
#     ip: 10.0.0.X
# ssh:
#   <hostname>:
#     host_key: |
#       <paste from /etc/ssh/ssh_host_ed25519_key on target>
#     host_key_pub: |
#       <paste from /etc/ssh/ssh_host_ed25519_key.pub on target>
```

### Step 7: Rebuild with Secrets

```bash
# On target, rebuild to get secrets
nixos-rebuild switch --flake .#<hostname>
```

### Step 8: Provision GPG/SSH with Nitrokey

Physically insert your Nitrokey into the target machine:

```bash
# On the target, as your user (not root)
su - brancengregory

# Fetch your public key from the keyserver
gpg --card-edit
# gpg/card> fetch
# gpg/card> quit

# Create stubs linking hardware to GPG
gpg-connect-agent "scd serialno" "learn --force" /bye

# Verify SSH key is available
ssh-add -L | grep cardno

# Test Git
ssh git@github.com
```

---

## Post-Deployment Verification

### Check sops-nix is working

```bash
# On target
systemctl status sops-nix

# Check secrets are decrypted
ls -la /run/secrets/
```

### Verify SSH host key

```bash
# Check host key matches what you recorded
ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
```

### Test hardware token

```bash
# Sign a test commit
git init /tmp/test-repo
cd /tmp/test-repo
git commit --allow-empty -m "Test hardware key signing"
git log --show-signature
```

---

## Troubleshooting

### nix-anywhere fails

- Ensure target has internet access
- Check SSH connectivity: `ssh root@<target-ip>`
- Verify flake evaluates: `nix flake check .#<hostname>`

### SSH key not found after install

- SSH keys are generated during first boot, not in the installer
- Wait for first boot to complete before extracting keys

### sops-nix fails to decrypt

- Verify `.sops.yaml` has the correct age public key
- Check the age key was derived correctly from SSH host key
- Run `sops updatekeys secrets/secrets.yaml` after adding new recipient

### Nitrokey not detected

- Check USB connection: `lsusb | grep -i nitro`
- Restart scdaemon: `gpgconf --kill scdaemon`
- Verify with: `gpg --card-status`

---

## Reference Commands

```bash
# Generate WireGuard keys
wg genkey | tee private.key | wg pubkey > public.key

# Convert SSH to age
ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub

# Get age public key from private key
age-keygen -y key.txt

# Edit secrets
sops secrets/secrets.yaml

# Update keys after .sops.yaml changes
sops updatekeys secrets/secrets.yaml
```

---

*Last Updated: 2026-04-06*  
*Workflow: nix-anywhere + hardware token*
