# Secret Management Guide

This document describes the ultra-secure, fully declarative secret management system for the NixOS infrastructure using **sops-nix**.

## Quick Start Guide

This section provides a quickstart for adding sops-nix to your Nix configuration. For comprehensive secret generation and management, see the sections below.

### Why sops-nix?

- **Atomic & Declarative:** Secrets are deployed alongside configuration
- **GitOps Friendly:** Encrypted secrets stored directly in Git (YAML/JSON)
- **Native Integration:** NixOS and Home Manager modules
- **Flexible Keys:** Works with Age and SSH keys

### Prerequisites

Tools are available via `nix develop` or:
```bash
nix-shell -p sops age ssh-to-age
```

### Basic Setup

**1. Add Flake Input:**
```nix
inputs.sops-nix = {
  url = "github:Mic92/sops-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**2. Configure `.sops.yaml`:**
```yaml
keys:
  - &user_brancen age1... # Your age public key
  - &host_powerhouse age1... # Convert from SSH: ssh-to-age

creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json)$
    key_groups:
      - age:
        - *user_brancen
        - *host_powerhouse
```

**3. Create Secrets:**
```bash
mkdir secrets
sops secrets/general.yaml
# Add secrets in the editor, save and close
```

**4. Configure System:**
```nix
sops.defaultSopsFile = ../../secrets/general.yaml;
sops.secrets."my_secret" = {};
```

**5. Configure Home Manager (Optional):**
```nix
sops.secrets.api_key = {
  path = "${config.home.homeDirectory}/.api_key";
  mode = "0600";
};
```

### Workflow

1. **Edit:** `sops secrets/general.yaml`
2. **Commit:** `git add secrets/ && git commit`
3. **Apply:** `nixos-rebuild switch` or `home-manager switch`
4. **Rotate:** `sops updatekeys secrets/general.yaml`

---

## Infrastructure Secret Management

For comprehensive infrastructure secrets (GPG keys, WireGuard, SSH host keys, etc.), see below.

## Architecture Overview

The secret management system follows these principles:

1. **Air-Gapped Generation**: All cryptographic secrets are generated in a secure, offline environment
2. **Encrypted Storage**: Secrets are encrypted with [sops](https://github.com/getsops/sops) using [age](https://age-encryption.org/)
3. **Version Control**: Encrypted secrets are committed to git, providing audit trail and backup
4. **Declarative Deployment**: Secrets are deployed via NixOS modules, no manual copying required
5. **Reproducibility**: Complete infrastructure can be rebuilt from git repository

## Secret Types

### 1. GPG Keys

**⚠️ IMPORTANT: GPG Secret Keys Are NOT Stored in SOPS**

GPG secret keys live exclusively on **Nitrokey 3 hardware tokens**. They are NEVER stored in SOPS or any filesystem.

- **Storage**: Hardware tokens only (Nitrokey 3)
- **Public Key**: Available in `keys/brancen-gregory-public.asc` and on keys.openpgp.org
- **Provisioning**: Manual via `gpg --card-edit` after inserting hardware token
- **Documentation**: See [Hardware Token Guide](./HARDWARE-KEYS.md) and [GPG/SSH Strategy](./GPG-SSH-STRATEGY.md)

**Key Information:**
- **Fingerprint**: `0A8C406B92CEFC33A51EC4933D9E0666449B886D`
- **Key ID**: `3D9E0666449B886D`
- **Keyserver**: https://keys.openpgp.org

### 2. WireGuard Keys
- **Hub (Capacitor)**: Server keys with listening port
- **Spokes**: Client keys with assigned IPs in 10.0.0.0/24
- **Preshared Keys**: Per-pair PSKs for additional security
- **Storage**: `secrets/secrets.yaml` under `wireguard:` tree

### 3. SSH Host Keys
- **Ed25519**: Primary host key for each machine
- **RSA** (optional): Legacy compatibility
- **Storage**: `secrets/secrets.yaml` under `ssh:` tree

### 4. Age Keys
- **Per-Host Keys**: Each host has its own age key for sops decryption
- **Your Master Key**: Your personal age key for editing secrets
- **Storage**: `secrets/secrets.yaml` under `age:` tree

### 5. Application Secrets
- **Restic**: Backup repository passwords
- **Database**: Connection strings and credentials
- **API Keys**: External service credentials
- **Storage**: `secrets/secrets.yaml` under application-specific trees

## Directory Structure

```
.
├── secrets/
│   ├── secrets.yaml              # Main encrypted secrets file
│   └── vm_host_key               # VM-specific SSH key (development)
├── keys/
│   └── brancen-gregory-public.asc # GPG public key backup (not secret)
├── .sops.yaml                    # SOPS configuration with age recipients
└── scripts/
    ├── generate-all-secrets.sh   # Generate infrastructure secrets
    └── generate-host-secrets.sh  # Generate secrets for single host
```

**Note**: GPG secret keys are NOT stored in this repository. They reside exclusively on Nitrokey 3 hardware tokens.

## Workflow

### Initial Setup (One-Time)

#### 1. Enter Development Shell

```bash
# Clone repository
git clone https://github.com/brancengregory/nix-config.git
cd nix-config

# Enter development shell (provides all required tools)
nix develop

# Verify tools are available
sops --version
age --version
wg --version
```

#### 2. Create Your Age Key

```bash
# Create directory for sops keys
mkdir -p ~/.config/sops/age

# Generate age key
age-keygen -o ~/.config/sops/age/keys.txt

# Note the public key - you'll add it to .sops.yaml
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

#### 3. Generate All Secrets

```bash
# Run the master generation script
./scripts/generate-all-secrets.sh

# This will:
# - Generate WireGuard keys for all hosts
# - Generate SSH host keys
# - Generate age keys for all hosts
# - Generate application secrets (restic, etc.)
# - Update .sops.yaml with new recipients
#
# NOTE: GPG keys are NOT generated - they are on Nitrokey hardware tokens
```

#### 4. Review and Commit

```bash
# Review the generated secrets
sops secrets/secrets.yaml

# Check .sops.yaml
sops -d .sops.yaml

# Commit everything
git add secrets/ .sops.yaml
git commit -m "feat: generate all infrastructure secrets"
git push
```

### Adding a New Host

```bash
# Generate secrets for new host
./scripts/generate-host-secrets.sh battery

# This will:
# - Assign next available IP (10.0.0.x)
# - Generate WireGuard keys
# - Generate SSH host keys
# - Generate age key
# - Update .sops.yaml

# Review and commit
git add secrets/ .sops.yaml
git commit -m "feat: add battery host secrets"
git push

# Create host configuration
mkdir -p hosts/battery
cp hosts/powerhouse/config.nix hosts/battery/
# ... customize for battery ...

# Deploy
nixos-install --flake .#battery
```

### Editing Secrets

```bash
# Edit secrets file
sops secrets/secrets.yaml

# Edit specific key
sops --set '["wireguard"]["powerhouse"]["private_key"] "new-value"' secrets/secrets.yaml

# Extract value
sops -d --extract '["wireguard"]["powerhouse"]["public_key"]' secrets/secrets.yaml
```

### Rotating Secrets

#### Rotate WireGuard Keys

```bash
# Generate new key
NEW_KEY=$(wg genkey)

# Update in sops
sops --set '["wireguard"]["powerhouse"]["private_key"] "'$NEW_KEY'"' secrets/secrets.yaml

# Update public key
NEW_PUB=$(echo "$NEW_KEY" | wg pubkey)
sops --set '["wireguard"]["powerhouse"]["public_key"] "'$NEW_PUB'"' secrets/secrets.yaml

# Commit and deploy
git commit -am "security: rotate powerhouse WireGuard keys"
nixos-rebuild switch --flake .#powerhouse
```

#### Rotate GPG Subkeys

**⚠️ Hardware Token Procedure**

GPG keys are stored on Nitrokey hardware tokens. To rotate:

1. Use offline master key backup to generate new subkeys
2. Move new subkeys to Nitrokey 3 (both primary and backup tokens)
3. Revoke old keys on keyserver
4. Update all authorized_keys files

See [Hardware Token Guide](./HARDWARE-KEYS.md) for detailed procedures.

#### Rotate Age Keys

```bash
# Generate new age key
NEW_KEY=$(age-keygen 2>&1)
NEW_PUB=$(echo "$NEW_KEY" | grep "Public key" | cut -d: -f2 | tr -d ' ')

# Update in secrets
sops --set '["age"]["powerhouse"]["public"] "'$NEW_PUB'"' secrets/secrets.yaml

# Update .sops.yaml (replace old key)
# ... edit .sops.yaml ...

# Re-encrypt all secrets with new recipients
sops updatekeys secrets/secrets.yaml
```

## Host Configuration

### Using Declarative Secrets in NixOS

#### WireGuard Hub Configuration (Capacitor)

```nix
{ config, ... }:
{
  imports = [ ../../modules/network ];  # Bundle: wireguard available
  
  networking.wireguard-mesh = {
    enable = true;
    nodeName = "capacitor";
    hubNodeName = "capacitor";  # This is the hub
    nodes = {
      capacitor = {
        ip = "10.0.0.1";
        publicKey = "CAPACITOR_PUBLIC_KEY";
        isServer = true;
      };
      powerhouse = {
        ip = "10.0.0.2";
        publicKey = "POWERHOUSE_PUBLIC_KEY";
      };
      # ... other nodes
    };
    privateKeyFile = config.sops.secrets."wireguard/capacitor/private_key".path;
  };
  
  # Declare secrets
  sops.secrets."wireguard/capacitor/private_key" = {};
}
```

#### WireGuard Spoke Configuration (Powerhouse)

```nix
{ config, ... }:
{
  imports = [ ../../modules/network ];  # Bundle: wireguard available
  
  networking.wireguard-mesh = {
    enable = true;
    nodeName = "powerhouse";
    hubNodeName = "capacitor";  # Connects to capacitor
    nodes = {
      capacitor = {
        ip = "10.0.0.1";
        publicKey = "CAPACITOR_PUBLIC_KEY";
        isServer = true;
        endpoint = "capacitor.example.com:51820";
      };
      powerhouse = {
        ip = "10.0.0.2";
        publicKey = "POWERHOUSE_PUBLIC_KEY";
      };
      # ... other nodes
    };
    privateKeyFile = config.sops.secrets."wireguard/powerhouse/private_key".path;
    presharedKeyFile = config.sops.secrets."wireguard/powerhouse/preshared_key".path;
  };
  
  # Declare secrets
  sops.secrets."wireguard/powerhouse/private_key" = {};
  sops.secrets."wireguard/powerhouse/preshared_key" = {};
}
```

#### GPG Hardware Token Support

**⚠️ GPG Secret Keys Are On Hardware Tokens, Not in SOPS**

```nix
{ config, ... }:
{
  imports = [ ../../modules/security ];  # Bundle: gpg, ssh available
  
  # Enable hardware token support (scdaemon, pcscd)
  # Secret keys are NOT imported - they remain on Nitrokey
  security.gpg = {
    enable = true;  # Enables smart card daemon support only
  };
  
  # After deployment, provision manually:
  # 1. Insert Nitrokey
  # 2. gpg --card-edit -> fetch -> quit
  # 3. gpg-connect-agent "scd serialno" "learn --force" /bye
  # 4. Test: ssh-add -L && git commit --allow-empty -m "Test"
}
```

**Note**: See [Hardware Token Guide](./HARDWARE-KEYS.md) for complete provisioning procedures.

#### SSH Host Keys

```nix
{ config, ... }:
{
  imports = [ ../../modules/security ];  # Bundle: gpg, ssh available
  
  services.openssh.hostKeysDeclarative = {
    enable = true;
    ed25519 = {
      privateKeyFile = config.sops.secrets."ssh/powerhouse/host_key".path;
      publicKeyFile = config.sops.secrets."ssh/powerhouse/host_key_pub".path;
    };
    extraAuthorizedKeys = [
      "ssh-ed25519 AAAAC3... brancengregory@turbine"
    ];
  };
  
  # Declare secrets
  sops.secrets."ssh/powerhouse/host_key" = {};
  sops.secrets."ssh/powerhouse/host_key_pub" = {};
}
```

## Security Considerations

### Threat Model

**Protected Against:**
- ✅ Secrets stored in plain text
- ✅ Secrets transmitted over network
- ✅ Accidental secret exposure in git
- ✅ Single point of failure (distributed keys)
- ✅ Lost laptop (per-device revocation)

**Requires Protection:**
- ⚠️ Your age master key (`~/.config/sops/age/keys.txt`)
- ⚠️ Machine running secret generation (air-gapped preferred)
- ⚠️ Git repository access (encrypted, but still sensitive)

### Best Practices

1. **Generate in Secure Environment**
   - Use air-gapped machine or live USB
   - No network connection during generation
   - Wipe temporary files securely

2. **Backup Your Age Master Key**
   ```bash
   # Print key for backup
   cat ~/.config/sops/age/keys.txt
   
   # Store in:
   # - Password manager
   # - Offline backup (USB in safe)
   # - Paper backup (write it down)
   ```

3. **Regular Rotation**
    - WireGuard keys: Every 6-12 months
    - GPG subkeys: Every 1-2 years (via hardware token re-flash)
    - Age keys: Every 2-3 years
    - Application passwords: As needed

4. **Hardware Token Security**
    - GPG keys never leave Nitrokey 3 hardware
    - Keep backup token in secure offline location
    - Never export or backup secret keys to files

4. **Access Control**
   - Limit who can decrypt secrets.yaml
   - Use separate age keys per admin
   - Document who has access in .sops.yaml

5. **Audit Trail**
   - Review git history for secret changes
   - Monitor for unauthorized modifications
   - Use signed commits for sensitive changes

### Recovery Scenarios

#### Lost Age Master Key

```bash
# You can still recover if you have access to any host's age key
# Extract from host:
sops -d --extract '["age"]["powerhouse"]["private"]' secrets/secrets.yaml > ~/.config/sops/age/keys.txt

# Then generate new master key and re-encrypt
age-keygen -o ~/.config/sops/age/keys.txt.new
# Update .sops.yaml with new public key
# Re-encrypt all secrets
sops updatekeys secrets/secrets.yaml
```

#### Lost Git Repository

```bash
# Clone from remote (secrets are encrypted)
git clone https://github.com/brancengregory/nix-config.git

# Decrypt with your age key
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
sops -d secrets/secrets.yaml

# Infrastructure can be fully restored
```

#### Compromised Host

```bash
# Revoke the compromised host's keys

# 1. Generate new keys for the host
./scripts/generate-host-secrets.sh compromised-host

# 2. Rotate WireGuard keys for all peers
#    (since PSK is compromised)
for host in powerhouse turbine capacitor battery; do
  if [ "$host" != "compromised-host" ]; then
    NEW_PSK=$(wg genpsk)
    sops --set '["wireguard"]["'$host'"]["preshared_key"] "'$NEW_PSK'"' secrets/secrets.yaml
  fi
done

# 3. Commit and deploy everywhere
git commit -am "security: rotate keys after compromise"
for host in powerhouse turbine capacitor battery; do
  nixos-rebuild switch --flake .#$host &
done
wait
```

## Troubleshooting

### SOPS "config file not found"

```bash
# Ensure .sops.yaml exists in repo root
ls -la .sops.yaml

# Check its content
sops -d .sops.yaml
```

### "Failed to decrypt"

```bash
# Verify age key is available
echo $SOPS_AGE_KEY_FILE
cat $SOPS_AGE_KEY_FILE

# Check if your key is in .sops.yaml recipients
sops -d .sops.yaml | grep "age:"

# Re-encrypt with your key
sops updatekeys secrets/secrets.yaml
```

### "Failed to write to secrets.yaml"

```bash
# Check file permissions
ls -la secrets/

# Ensure directory is writable
chmod u+w secrets/

# Check if file is locked by another process
lsof secrets/secrets.yaml
```

### Hardware Token Not Working

**Issue**: GPG operations fail, `gpg --card-status` shows no card

**Solution**:
```bash
# Check if Nitrokey is detected
gpg --card-status

# If not detected, check USB connection
lsusb | grep -i nitro

# Restart scdaemon
gpgconf --kill scdaemon
gpg-connect-agent /bye

# Fetch public key from keyserver
gpg --card-edit
# gpg/card> fetch
# gpg/card> quit

# Create stubs
gpg-connect-agent "scd serialno" "learn --force" /bye

# Verify
gpg --list-secret-keys
ssh-add -L | grep cardno
```

See [Hardware Token Guide](./HARDWARE-KEYS.md) for complete troubleshooting.

## Migration from energize.sh

The old `energize.sh` script generated secrets manually on each host. The new system is fully declarative:

| Aspect | energize.sh (Old) | New System |
|--------|-------------------|------------|
| Generation | Per-host manual | Centralized, air-gapped |
| Storage | Plain text files | Encrypted in git |
| Distribution | Manual copy | Declarative NixOS |
| Backup | None | Git history + age keys |
| Rotation | Manual | Scripted |
| Reproducibility | None | Complete from git |

### Migration Steps

1. **Backup Existing Keys**
    ```bash
    # On each host
    tar czf ~/keys-backup.tar.gz ~/.ssh /etc/ssh
    # NOTE: Do NOT backup ~/.gnupg secret keys - they are on hardware tokens
    ```

2. **Generate New Declarative Secrets**
   ```bash
   # In secure environment
   ./scripts/generate-all-secrets.sh
   ```

3. **Update Host Configurations**
   - Add new modules to each host
   - Reference new secret paths
   - Remove old key references

4. **Deploy**
   ```bash
   # Deploy to each host
   nixos-rebuild switch --flake .#powerhouse
   # ... repeat for each host
   ```

5. **Verify**
    - Check hardware token: `gpg --card-status`
    - Check WireGuard: `wg show`
    - Check SSH: `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`

## See Also

- [Hardware Token Guide](./HARDWARE-KEYS.md) - Nitrokey 3 setup and daily operation
- [GPG/SSH Strategy](./GPG-SSH-STRATEGY.md) - Hardware-first authentication workflow
- [Deployment Guide](./DEPLOYMENT.md) - New host provisioning with hardware tokens
- [SOPS](https://github.com/getsops/sops) - Secrets OPerationS tool
- [Age](https://github.com/FiloSottile/age) - Modern encryption tool

---

*Last Updated: 2026-03-04*  
*Hardware Token Model - No Software GPG Keys*
