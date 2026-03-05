# Unified GPG/SSH Strategy (Hardware Token Edition)

**Hardware-backed authentication using Nitrokey 3 tokens with automatic stub management**

This document outlines the hardware-first GPG/SSH configuration where all secret keys reside exclusively on Nitrokey 3 hardware tokens, and hosts use lightweight "stubs" that reference keys on the hardware.

---

## Overview

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER APPLICATIONS                        │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐│
│  │   GPG Client    │    │   SSH Client    │    │ Git (signed)││
│  └─────────┬───────┘    └─────────┬───────┘    └──────┬──────┘│
│            │                      │                   │       │
│            └──────────────────────┼───────────────────┘       │
│                                   │                           │
│                      ┌─────────────▼──────────────┐           │
│                      │        GPG Agent          │            │
│                      │  ┌─────────────────────┐ │            │
│                      │  │ Stub Management    │ │            │
│                      │  │ SSH Auth Bridge    │ │            │
│                      │  │ Smart Card Daemon  │ │            │
│                      │  └─────────────────────┘ │            │
│                      └───────────┬──────────────┘            │
└──────────────────────────────────┼────────────────────────────┘
                                   │
                    ┌──────────────▼───────────────┐
                    │      HARDWARE TOKEN          │
                    │   ┌──────────────────────┐  │
                    │   │ Nitrokey 3            │  │
                    │   │ ├─ Signing Subkey    │  │
                    │   │ ├─ Encryption Subkey │  │
                    │   │ └─ Auth Subkey (SSH) │  │
                    │   └──────────────────────┘  │
                    └───────────────────────────────┘
```

### Key Principles

1. **Hardware-First:** All secret keys live exclusively on Nitrokey 3 tokens
2. **Stub Model:** Hosts have lightweight references (stubs), not actual keys
3. **Automatic Discovery:** Stubs created automatically when hardware key is used
4. **Cross-Platform:** Identical workflow on Linux (powerhouse/capacitor) and macOS (turbine)
5. **Manual Provisioning:** No automated scripts - fully documented procedures

### What Changed from Per-Host Model

| Aspect | Old Model | New Model |
|--------|-----------|-----------|
| **Key Storage** | Per-host keys in SOPS | Single hardware key pair |
| **Secret Material** | Filesystem + SOPS | Hardware token only |
| **Host Keys** | Different per host | Same keys everywhere |
| **Provisioning** | Import from SOPS | Stubs from hardware |
| **Backup Strategy** | SOPS backups | Identical backup token |

---

## How Stubs Work

### What is a Stub?

A **stub** is a lightweight reference file stored in `~/.gnupg/private-keys-v1.d/` that:
- Points to a key on the hardware token (by serial number)
- Contains key metadata (algorithm, keygrip)
- **Does NOT contain secret key material**

### Stub vs. Full Key

**Full Key (NOT used in this model):**
```
~/.gnupg/private-keys-v1.d/XXXXXXX.key:
- Secret key material (encrypted)
- Can decrypt/sign without hardware
- Size: ~1-2 KB
```

**Stub (what we use):**
```
~/.gnupg/private-keys-v1.d/XXXXXXX.key:
- Keygrip reference
- Hardware token serial
- Algorithm info
- No secret material
- Size: ~200 bytes
- Points to hardware for actual operations
```

### Creating Stubs

**Automatic (Preferred):**
```bash
# 1. Insert Nitrokey

# 2. Any GPG operation creates stubs
gpg --card-status        # View token info (creates stubs)
ssh-add -L              # View SSH key (creates auth stub)
git commit -m "test"     # Sign (creates signing stub)

# 3. Stubs now exist
gpg --list-secret-keys
# Shows: 'ssb>' notation (secret subkey stub)
```

**Manual (if automatic fails):**
```bash
# Fetch public key from keyserver
gpg --card-edit
# gpg/card> fetch
# gpg/card> quit

# Force stub creation
gpg-connect-agent "scd serialno" "learn --force" /bye
```

---

## Magic Recovery (New Machine Setup)

### Overview

Setting up GPG/SSH on a new machine with existing hardware keys:

**Before:** Needed to import secret keys from backup/SOPS  
**After:** Just plug in token and create stubs

### Procedure

**Step 1: Install System**
```bash
# Install NixOS or home-manager as normal
# See docs/DEPLOYMENT.md for full procedure
```

**Step 2: Insert Nitrokey**
```bash
# Physically insert token into USB port
# Wait for LED to stabilize (steady light)
```

**Step 3: Fetch Public Key**
```bash
# Download from keyserver
gpg --card-edit
# gpg/card> fetch  # Automatically fetches from keys.openpgp.org
# gpg/card> quit

# Alternative: Import from local copy
gpg --import keys/brancen-gregory-public.asc
```

**Step 4: Create Stubs**
```bash
# Link hardware to GPG (creates stubs)
gpg-connect-agent "scd serialno" "learn --force" /bye

# Or simply use any GPG operation
gpg --list-secret-keys  # Shows stubs created
```

**Step 5: Verify SSH**
```bash
# Check SSH key is available
ssh-add -L

# Expected output:
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH... cardno:000F_XXXXXXXX
```

**Step 6: Test**
```bash
# Test SSH authentication
ssh git@github.com
# Should show: Hi brancengregory! You've successfully authenticated...

# Test Git signing
git commit --allow-empty -m "Test hardware key signing"
git log --show-signature -1
# Should show: Good signature from "Brancen Gregory"
```

### Result

- ✅ No secret key import needed
- ✅ No SOPS secrets for GPG
- ✅ Stubs created automatically
- ✅ Hardware provides all secret operations
- ✅ Both Nitrokeys work identically

---

## Daily Workflow

### SSH Authentication

**Automatic (once stubs exist):**
```bash
ssh user@server
# System prompts for PIN (if cache expired)
# LED blinks - touch token
# Authentication complete
```

**With Tmux:**
```bash
tmux new-session -s work
ssh user@server  # Works seamlessly in tmux

# If issues:
refresh_gpg  # Updates GPG_TTY for current pane
```

### Git Commit Signing

**Automatic (enabled by default):**
```bash
git commit -m "Update configuration"
# Automatically signed with hardware key
# PIN prompt if cache expired
# Touch token when LED blinks
```

**Verify Signature:**
```bash
git log --show-signature
# Shows: Good signature from "Brancen Gregory <brancengregory@gmail.com>"
```

### GPG Operations

**Encrypt File:**
```bash
gpg --encrypt --recipient brancengregory@gmail.com file.txt
# PIN prompt
# Touch token
# Encrypted file created
```

**Sign File:**
```bash
gpg --sign file.txt
# PIN prompt
# Touch token
# Signed file created
```

---

## Key Management

### Your Keys

**Hardware Token Keys:**
- **Fingerprint:** `0A8C406B92CEFC33A51EC4933D9E0666449B886D`
- **Key ID:** `3D9E0666449B886D`
- **Keyserver:** https://keys.openpgp.org

**Key Structure:**
```
Master Key (Certify only)
├─ Signing Subkey     → Git commit signing
├─ Encryption Subkey  → File/email encryption
└─ Authentication Subkey → SSH authentication
```

### Keyserver Integration

**Publish Key:**
```bash
# If you update/extend keys
gpg --keyserver hkps://keys.openpgp.org --send-keys 3D9E0666449B886D
```

**Fetch on New Machine:**
```bash
gpg --card-edit
# gpg/card> fetch
# gpg/card> quit

# Or directly:
curl https://keys.openpgp.org/vks/v1/by-fingerprint/0A8C406B92CEFC33A51EC4933D9E0666449B886D | gpg --import
```

### Local Backup

**Public Key in Repository:**
```bash
# Located at: keys/brancen-gregory-public.asc
# Use if keyserver unavailable:
gpg --import keys/brancen-gregory-public.asc
```

---

## Hardware Token Details

### Device Information

**Primary Token:**
- Model: Nitrokey 3
- Serial: [Check with `gpg --card-status`]
- Location: [Your secure location]
- Usage: Daily operations

**Backup Token:**
- Model: Nitrokey 3
- Serial: [Check with `gpg --card-status`]
- Location: [Your backup secure location]
- Usage: Emergency/backup (identical keys)

### PIN Management

**User PIN:** 6-8 digits
- Daily operations (sign, encrypt, auth)
- 3 attempts before temporary lock
- Unlocked with Admin PIN

**Admin PIN:** (change from default during setup!)
- Card administration
- Reset User PIN
- Never for daily use

**Change PINs:**
```bash
gpg --card-edit
# gpg/card> admin
# gpg/card> passwd
# Follow prompts
# gpg/card> quit
```

### Touch Confirmation (UIF)

**User Interface Flags (UIF):**
- Configured: All subkeys require touch
- LED blinks when touch needed
- Press token surface to confirm

**Verify:**
```bash
gpg --card-edit
# gpg/card> uif
# Shows current UIF status
```

---

## Configuration

### Current Configuration Files

**GPG Agent** (`modules/home/gpg.nix`):
```nix
services.gpg-agent = {
  enable = true;
  enableSshSupport = true;
  enableScDaemon = true;  # Smart card daemon for hardware tokens
  
  # Cache settings
  defaultCacheTtl = 28800;      # 8 hours
  defaultCacheTtlSsh = 28800;   # 8 hours
  maxCacheTtl = 86400;          # 24 hours
  maxCacheTtlSsh = 86400;       # 24 hours
};
```

**Git Signing** (`modules/home/programs/git.nix`):
```nix
signing = {
  key = "3D9E0666449B886D";  # Hardware token subkey
  signByDefault = true;
};
```

**ZSH Integration** (`modules/home/terminal/zsh.nix`):
```nix
# Environment setup
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# Hardware token aliases
nitro-status = "gpg --card-status";
nitro-fetch = "gpg --card-edit";
nitro-learn = "gpg-connect-agent 'scd serialno' 'learn --force' /bye";
```

### Tmux Integration

**Configuration** (`modules/home/terminal/tmux.nix`):
```nix
set-option -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION SSH_AUTH_SOCK WINDOWID XAUTHORITY GPG_TTY"

# Refresh GPG_TTY on session events
set-hook -g session-created 'run-shell "export GPG_TTY=$(tty) && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true"'
set-hook -g client-attached 'run-shell "export GPG_TTY=$(tty) && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true"'
```

---

## Troubleshooting

### Hardware Token Not Detected

**Symptom:** `gpg --card-status` shows "No such device"

**Solutions:**
```bash
# Check USB
lsusb | grep -i nitro

# Check scdaemon
gpgconf --check-programs
ps aux | grep scdaemon

# Restart
gpgconf --kill scdaemon
gpg-connect-agent /bye

# Try different port
```

### SSH Key Not Available

**Symptom:** `ssh-add -L` doesn't show cardno key

**Solutions:**
```bash
# Create stubs
gpg-connect-agent "scd serialno" "learn --force" /bye

# Check GPG agent
echo $SSH_AUTH_SOCK
gpgconf --list-dirs agent-ssh-socket

# Restart agent
gpgconf --kill gpg-agent && gpgconf --launch gpg-agent
```

### Git Signing Fails

**Symptom:** `git commit` fails with GPG error

**Solutions:**
```bash
# Check signing key
git config user.signingkey
# Should be: 3D9E0666449B886D

# Test GPG directly
echo "test" | gpg --clearsign

# Check stubs
gpg --list-secret-keys 3D9E0666449B886D
```

### PIN Entry Issues

**Symptom:** PIN dialog doesn't appear

**Solutions:**
```bash
# Set GPG_TTY
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye

# Test pinentry
echo "GETPIN" | pinentry-curses

# In tmux:
refresh_gpg
```

---

## Security Model

### Threat Protection

**Hardware Token Provides:**
- ✅ Physical possession requirement
- ✅ Keys never leave hardware (even during operations)
- ✅ Protection against key extraction attacks
- ✅ 5th Amendment protection (can't be compelled to reveal PIN)
- ✅ PIN + touch dual authentication

**SSH Host Keys Provide:**
- ✅ Server identity verification
- ✅ Protection against man-in-the-middle attacks
- ✅ Pre-distributed trust (no TOFU)

**SOPS Provides:**
- ✅ Encrypted secret distribution
- ✅ Host-specific credentials
- ✅ Declarative configuration

### Trust Model

```
┌─────────────────────────────────────────┐
│        TRUST HIERARCHY                │
├─────────────────────────────────────────┤
│ 1. Hardware Token (Root of Trust)      │
│    └─ Physical possession + PIN        │
│                                         │
│ 2. SSH Host Keys (Server Identity)     │
│    └─ Pre-verified in SOPS             │
│                                         │
│ 3. SOPS + Age (Secret Distribution)    │
│    └─ Host-specific decryption         │
└─────────────────────────────────────────┘
```

---

## Best Practices

### Daily Use

1. **Insert token when starting work**
2. **Remove when done** (optional but good practice)
3. **Verify LED behavior:**
   - Steady = ready
   - Blinking = touch needed
4. **Use aliases for common operations**

### Security

1. **Never export secret keys** (they stay on hardware)
2. **Backup token kept offline** (emergency only)
3. **Public key published** (keyserver + repo backup)
4. **PIN not written down** (memorize only)
5. **Touch required** (UIF enabled for all operations)

### Maintenance

1. **Monthly:** Test backup token
2. **Quarterly:** Verify keyserver publication
3. **Annually:** Consider subkey rotation

---

## Migration from Old Model

### For Existing Installations

**If you have per-host GPG keys in SOPS:**

1. **Backup existing GPG directory:**
   ```bash
   cp -r ~/.gnupg ~/.gnupg.backup.$(date +%Y%m%d)
   ```

2. **Remove old keys:**
   ```bash
   rm -rf ~/.gnupg/private-keys-v1.d/*
   rm ~/.gnupg/pubring.kbx*
   ```

3. **Provision with hardware token:**
   ```bash
   gpg --card-edit
   # fetch
   # quit
   gpg-connect-agent "scd serialno" "learn --force" /bye
   ```

4. **Verify:**
   ```bash
   gpg --list-secret-keys  # Should show stubs
   ssh-add -L              # Should show cardno
   git commit --allow-empty -m "Test"
   ```

5. **Clean SOPS:**
   ```bash
   # Remove GPG sections from secrets/secrets.yaml
   # See docs/DEPLOYMENT.md
   ```

---

## Related Documentation

- **Hardware Tokens:** `docs/HARDWARE-KEYS.md` - Detailed token management
- **Deployment:** `docs/DEPLOYMENT.md` - New machine provisioning
- **Secret Management:** `docs/SECRET_MANAGEMENT.md` - SOPS and age keys
- **Security:** `docs/SECURITY.md` - Threat model and practices
- **FIDO2 (Future):** `docs/FIDO2-RESIDENT-KEYS.md` - Alternative SSH method
- **Public Key:** `keys/brancen-gregory-public.asc` - Local backup

---

## Quick Reference Commands

```bash
# Check token
gpg --card-status

# Create stubs
gpg-connect-agent "scd serialno" "learn --force" /bye

# List keys with stubs
gpg --list-secret-keys

# Show SSH key
ssh-add -L | grep cardno

# Fetch from keyserver
gpg --card-edit -> fetch -> quit

# Restart agent
gpgconf --kill gpg-agent && gpgconf --launch gpg-agent

# Refresh in tmux
refresh_gpg

# Hardware token aliases
nitro-status    # gpg --card-status
nitro-fetch     # gpg --card-edit
nitro-learn     # Create stubs
```

---

*Last Updated: 2026-03-04*  
*Hardware Token Model - No Per-Host Keys*
