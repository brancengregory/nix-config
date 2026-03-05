# Hardware Token Management Guide

**Nitrokey 3 GPG Hardware Token Reference**

This guide covers the management and daily operation of Nitrokey 3 hardware tokens for GPG-based authentication, encryption, and signing.

---

## Overview

All GPG secret keys live exclusively on Nitrokey 3 hardware tokens. This repository uses the **"stub" model** where hosts have only references (stubs) to keys, while the actual cryptographic material resides on hardware.

**Key Benefits:**
- Keys never leave the hardware token (even during use)
- Strong protection against key extraction attacks
- Physical possession required for authentication
- 5th Amendment protection (can't be compelled to reveal hardware PIN)

---

## Hardware Setup

### Devices

**Primary Token:** Nitrokey 3
- **Serial:** [Record from `gpg --card-status`]
- **Status:** Daily use
- **Location:** [Your secure location]

**Backup Token:** Nitrokey 3
- **Serial:** [Record from `gpg --card-status`]
- **Status:** Identical copy, kept offline
- **Location:** [Your backup secure location]

### Key Structure

Each token contains:
```
┌─────────────────────────────────────────┐
│           GPG Key Structure             │
├─────────────────────────────────────────┤
│  Master Key (Certify only)             │
│    └─ Never used directly                │
│                                          │
│  Subkey 1: Signing (S)                  │
│    └─ Git commit signing                 │
│                                          │
│  Subkey 2: Encryption (E)               │
│    └─ File/email encryption              │
│                                          │
│  Subkey 3: Authentication (A)         │
│    └─ SSH authentication                 │
└─────────────────────────────────────────┘
```

**Your Keys:**
- **Fingerprint:** `0A8C406B92CEFC33A51EC4933D9E0666449B886D`
- **Key ID:** `3D9E0666449B886D`
- **Algorithm:** Ed25519 (Curve25519 for encryption)

---

## Daily Operation

### Using the Token

1. **Insert Nitrokey** into USB port
2. **LED Behavior:**
   - Steady: Ready
   - Blinking: Operation in progress (touch required)
   - Off: No power/not detected

3. **Perform Operation** (SSH, git commit, etc.)
4. **PIN Entry:**
   - User PIN: 6-8 digits
   - Enter when prompted by pinentry
   
5. **Touch Confirmation:**
   - LED blinks = touch required
   - Press the touch sensor on the token
   - Operation completes

6. **Remove Token** when done (optional, but good practice)

### PIN Management

**User PIN:** 6-8 digits (daily use)
- Used for normal operations (sign, encrypt, auth)
- 3 attempts before temporary lock
- Unlock with Admin PIN

**Admin PIN:** Default 12345678 (change during setup!)
- Used for card administration
- Change PINs, reset retry counters
- Never use for daily operations

**PIN Change Procedure:**
```bash
gpg --card-edit
# gpg/card> admin
# gpg/card> passwd
# Follow prompts for User PIN and Admin PIN
# gpg/card> quit
```

---

## Stub Management

### What Are Stubs?

Stubs are lightweight references stored in `~/.gnupg/private-keys-v1.d/` that point to keys on the hardware token. They contain:
- Key ID
- Hardware token serial number
- Algorithm info

**NOT the actual secret key** (that stays on the token)

### Checking Stubs

```bash
# List all keys (look for 'ssb>' for stubs)
gpg --list-secret-keys

# View stubs directly
ls ~/.gnupg/private-keys-v1.d/

# Check specific key
gpg --list-secret-keys 3D9E0666449B886D
```

### Creating Stubs

**Automatic (First Use):**
```bash
# Simply insert token and use it
gpg --card-status  # Shows token is recognized
ssh-add -L         # Shows SSH key from token
git commit -m "Test"  # Creates signing stub
```

**Manual (if automatic fails):**
```bash
# 1. Fetch public key from keyserver
gpg --card-edit
# gpg/card> fetch
# gpg/card> quit

# 2. Create stubs by linking hardware
gpg-connect-agent "scd serialno" "learn --force" /bye

# 3. Verify stubs created
gpg --list-secret-keys
```

### Stub Location

```
~/.gnupg/
├── private-keys-v1.d/
│   ├── [Keygrip].key       # Stub file (very small, ~300 bytes)
│   └── ...
└── ...
```

**IMPORTANT:** Stubs are safe to delete and recreate - they don't contain secret material. If you delete them, just reinsert the token and they'll be recreated.

---

## Keyserver Integration

### Publishing Your Key

Your public key should be published to keys.openpgp.org:

```bash
# Send to keyserver
gpg --keyserver hkps://keys.openpgp.org --send-keys 3D9E0666449B886D

# Verify it's there
gpg --keyserver hkps://keys.openpgp.org --search-keys brancengregory@gmail.com
```

### Fetching on New Machine

```bash
# From keyserver
gpg --card-edit
# gpg/card> fetch
# gpg/card> quit

# Or direct download
curl -o /tmp/key.asc https://keys.openpgp.org/vks/v1/by-fingerprint/0A8C406B92CEFC33A51EC4933D9E0666449B886D
gpg --import /tmp/key.asc
```

### Local Backup

Repository contains public key at:
- `keys/brancen-gregory-public.asc`

Use if keyserver is unavailable:
```bash
gpg --import keys/brancen-gregory-public.asc
```

---

## Verification Procedures

### Verify Token is Working

```bash
# 1. Check card status
gpg --card-status

# Should show:
# - Card type: Nitrokey
# - Serial number
# - Application ID
# - Status: User PIN initialized

# 2. Test SSH key
ssh-add -L | grep "cardno"

# Should show SSH public key with "cardno:" suffix

# 3. Test signing
echo "test" | gpg --clearsign

# Should prompt for PIN, then output signed message

# 4. Test SSH authentication
ssh git@github.com

# Should authenticate successfully (may require touch)
```

### Verify Both Tokens Work

```bash
# Test primary token
# 1. Insert primary
gpg --card-status
ssh-add -L

# 2. Remove, insert backup
gpg --card-status
ssh-add -L

# Both should show same key fingerprint
```

---

## Troubleshooting

### Token Not Detected

**Symptom:** `gpg --card-status` shows "No such device"

**Solutions:**
```bash
# 1. Check USB connection
lsusb | grep -i nitro

# 2. Check scdaemon is running
ps aux | grep scdaemon
gpgconf --check-programs

# 3. Restart scdaemon
gpgconf --kill scdaemon
gpg-connect-agent /bye

# 4. Check permissions
# Linux: Ensure user is in 'plugdev' or similar group
# macOS: Grant permission in System Preferences > Security

# 5. Try different USB port
```

### PIN Entry Issues

**Symptom:** PIN entry dialog doesn't appear or fails

**Solutions:**
```bash
# Check pinentry is configured
gpgconf --check-programs

# Test pinentry directly
echo "GETPIN" | pinentry-curses

# For tmux issues, use refresh_gpg alias
refresh_gpg

# Set GPG_TTY explicitly
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye
```

### Wrong PIN / Locked Out

**Symptom:** "Card error" after 3 wrong PIN attempts

**Recovery:**
```bash
# 1. Use Admin PIN to reset User PIN
gpg --card-edit
# gpg/card> admin
# gpg/card> passwd
# Choose: 1 = change PIN
# Enter Admin PIN
# Set new User PIN

# 2. If Admin PIN also locked (10 attempts):
#    - Token is permanently locked for admin functions
#    - Keys are still usable if you know the User PIN
#    - Use backup token for admin operations
```

### SSH Key Not Showing

**Symptom:** `ssh-add -L` doesn't show cardno key

**Solutions:**
```bash
# 1. Check GPG agent is running
gpgconf --check-programs

# 2. Verify SSH socket
echo $SSH_AUTH_SOCK

# 3. Link hardware (create stubs)
gpg-connect-agent "scd serialno" "learn --force" /bye

# 4. Restart GPG agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

# 5. Check SSH key from GPG
gpg --export-ssh-key 3D9E0666449B886D
```

### Git Signing Fails

**Symptom:** `git commit` fails with GPG error

**Solutions:**
```bash
# 1. Check git signing key
git config --global user.signingkey

# Should be: 3D9E0666449B886D

# 2. Test signing directly
echo "test" | gpg --clearsign

# 3. Check GPG can find secret key
gpg --list-secret-keys 3D9E0666449B886D

# 4. Verify stub exists
ls ~/.gnupg/private-keys-v1.d/ | grep [keygrip]
```

---

## Maintenance

### Firmware Updates

**CAUTION:** Firmware updates can wipe keys. Ensure backup token is working first.

```bash
# Check current firmware
nitropy nk3 status

# Update firmware
nitropy nk3 update

# Verify after update
nitropy nk3 status
gpg --card-status
```

### Periodic Checks

**Monthly:**
```bash
# Verify both tokens work
# Check card status on each
# Test SSH authentication
# Test git signing
```

**Quarterly:**
```bash
# Review keyserver publication
# Check key expiration (should be 1 year for subkeys)
# Verify backup token accessibility
```

**Annually:**
```bash
# Consider subkey rotation
# Update firmware if needed
# Review security procedures
```

---

## Emergency Procedures

### Lost or Damaged Token

**Scenario:** Primary token lost or damaged

**Recovery:**
```bash
# 1. Retrieve backup token
# 2. Use backup for all operations (identical keys)
# 3. Order replacement Nitrokey 3
# 4. Perform key ceremony on new token (from master key backup)
# 5. Update docs with new token serial
```

### Token Stolen

**Scenario:** Token stolen by adversary

**Response:**
```bash
# 1. Immediately use backup token to generate revocation cert
#    (if you have offline master key backup)

# 2. Revoke subkeys on keyserver
# gpg --keyserver hkps://keys.openpgp.org --send-keys [revocation]

# 3. Rotate to new keys on replacement token
# 4. Update all authorized_keys files
# 5. Notify contacts of key change
```

**Note:** With only the token (no PIN), adversary cannot use keys. PIN provides additional protection.

### Both Tokens Compromised

**Scenario:** Both tokens lost/stolen

**Recovery:**
```bash
# 1. Use offline master key backup to generate new subkeys
# 2. Get new Nitrokey devices
# 3. Move new subkeys to new tokens
# 4. Revoke old keys
# 5. Update all systems
```

**This is why offline master key backup is CRITICAL.**

---

## Quick Reference

### Essential Commands

```bash
# Check token status
gpg --card-status

# List keys with stubs
gpg --list-secret-keys

# Show SSH key
ssh-add -L | grep cardno

# Create/link stubs
gpg-connect-agent "scd serialno" "learn --force" /bye

# Refresh GPG in current shell
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye

# Restart GPG agent
gpgconf --kill gpg-agent && gpgconf --launch gpg-agent
```

### ZSH Aliases

```bash
nitro-status    # gpg --card-status
nitro-fetch     # gpg --card-edit (then fetch)
nitro-learn     # gpg-connect-agent link stubs
nitro-keys      # gpg --list-secret-keys
ssh-gpg-keys    # ssh-add -L | grep cardno
gpg-restart     # Restart GPG agent
```

---

## Related Documentation

- **Deployment:** `docs/DEPLOYMENT.md` - New machine provisioning
- **GPG/SSH Strategy:** `docs/GPG-SSH-STRATEGY.md` - Complete workflow
- **Secret Management:** `docs/SECRET_MANAGEMENT.md` - SOPS and age keys
- **Security Guidelines:** `docs/SECURITY.md` - Threat model and practices
- **Public Key:** `keys/brancen-gregory-public.asc` - Local backup

---

*Last Updated: 2026-03-04*
