# FIDO2 Resident Keys (Future Capability)

**Documentation for hardware-backed SSH keys using FIDO2/CTAP2 protocol**

⚠️ **NOTE:** This is documentation-only for future capability. Do not implement on current hosts without specific operational need.

---

## Overview

FIDO2 Resident Keys (also called "discoverable credentials") are SSH keys stored in the hardware token's **Secure Element** memory. Unlike GPG-based SSH authentication, these keys:

- **Reside on hardware:** Private key never leaves the token
- **Discoverable:** Can be loaded on any machine with `ssh-add -K`
- **No GPG required:** Direct hardware-backed SSH without GPG agent
- **Protocol:** Uses FIDO2/CTAP2 via libfido2

---

## Use Cases

### When to Use FIDO2 Resident Keys

✅ **Appropriate Scenarios:**

1. **Satellite/Sporadic Access**
   - Accessing a server from a trusted but temporary machine
   - Conference laptops, coworking spaces
   - When you can't/don't want to set up full GPG environment

2. **Server-to-Server SSH**
   - `powerhouse` or `capacitor` authenticating to other infrastructure
   - Automated but hardware-backed access
   - When GPG agent is undesirable

3. **Emergency Access**
   - When primary Nitrokey unavailable
   - Quick access from newly provisioned machine

4. **Cross-Platform Consistency**
   - Windows machines where GPG setup is complex
   - Systems with limited GPG support

### When NOT to Use

❌ **Inappropriate Scenarios:**

1. **Workstation Daily Use**
    - Workstations are frequently in BFU (Before First Unlock) state
    - Resident keys are useless when device is powered off
    - GPG-based is superior for daily workstation use

2. **When GPG Already Configured**
   - Don't duplicate functionality
   - GPG provides additional features (signing, encryption)

3. **Untrusted Machines**
   - Resident keys prove "you have the hardware"
   - But don't protect against compromised host
   - Always verify machine integrity first

---

## Technical Details

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    SSH FIDO2 Flow                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Client                                Server          │
│    │                                     │             │
│    │  ssh user@server                    │             │
│    │ ─────────────────────────────────> │             │
│    │                                     │             │
│    │  Challenge (random nonce)           │             │
│    │ <───────────────────────────────── │             │
│    │                                     │             │
│    │  ┌─────────────────────────────┐   │             │
│    │  │  Nitrokey Hardware Token   │   │             │
│    │  │  - Receives challenge       │   │             │
│    │  │  - Signs with private key   │   │             │
│    │  │    (never leaves device)     │   │             │
│    │  │  - User touches device      │   │             │
│    │  └─────────────────────────────┘   │             │
│    │                                     │             │
│    │  Signed response                    │             │
│    │ ─────────────────────────────────> │             │
│    │                                     │             │
│    │  Authentication success           │             │
│    │ <───────────────────────────────── │             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Key Types

**`-t ed25519-sk`**: Ed25519 with FIDO2/hardware support
- **sk** = Security Key
- Uses hardware's internal cryptographic processor
- Ed25519 curve (same as GPG auth subkey)

**`-t ecdsa-sk`**: ECDSA with FIDO2/hardware support
- Alternative to Ed25519-sk
- Use only if Ed25519 not supported

### Options

**`-O resident`**: Store key as resident/discoverable
- Private key stored in hardware Secure Element
- Can be "discovered" with `ssh-add -K` on any machine
- Without this, key is hardware-backed but not resident

**`-O application=ssh:NAME`**: Label the resident key
- Helps identify which key is which on the hardware
- Useful if you have multiple resident keys
- Name should describe purpose: `ssh:powerhouse-A`, `ssh:capacitor-backup`

**`-O verify-required`**: Require user verification (PIN)
- In addition to touch, requires PIN entry
- More secure but slower
- Consider for high-security scenarios

**`-O no-touch-required`**: Skip touch confirmation
- Faster but less secure
- NOT recommended for production use

---

## Generation Procedure

### Step 1: Prerequisites

```bash
# Ensure libfido2 is installed
# On NixOS: usually included with openssh
# Verify FIDO2 support
ssh -V  # Should show "with FIDO2 support"
```

### Step 2: Generate Resident Key

```bash
# Insert Nitrokey

# Generate key
ssh-keygen -t ed25519-sk -O resident -O application=ssh:HOSTNAME-X -f ~/.ssh/id_fido2_HOSTNAME

# Example for powerhouse:
ssh-keygen -t ed25519-sk -O resident -O application=ssh:powerhouse-A -f ~/.ssh/id_fido2_powerhouse

# Output:
# Generating public/private ed25519-sk key pair.
# You may need to touch your authenticator to authorize the generation.
# (Touch Nitrokey when LED blinks)
# Enter passphrase (empty for no passphrase):
# Your identification has been saved in ~/.ssh/id_fido2_powerhouse
# Your public key has been saved in ~/.ssh/id_fido2_powerhouse.pub
```

### Step 3: Record Key Information

```bash
# View public key
cat ~/.ssh/id_fido2_powerhouse.pub

# Format:
# sk-ssh-ed25519@openssh.com AAAAC3NzaC... cardno:000F_XXXXXXXX

# Key components:
# - sk-ssh-ed25519@openssh.com: Key type (FIDO2 Ed25519)
# - AAAAC3NzaC...: Public key material
# - cardno:000F_XXXXXXXX: Hardware token serial number
```

### Step 4: Distribute Public Key

**Add to server authorized_keys:**
```bash
# On server (e.g., capacitor)
echo "sk-ssh-ed25519@openssh.com AAAAC3NzaC... cardno:000F_XXXXXXXX" >> ~/.ssh/authorized_keys

# Or via SSH:
ssh-copy-id -i ~/.ssh/id_fido2_powerhouse.pub user@capacitor
```

---

## Discovery Procedure

### Loading Keys on New Machine

```bash
# On a new/trusted machine where you want to use the key:

# 1. Insert Nitrokey

# 2. Discover resident keys
ssh-add -K

# Output:
# Enter PIN for authenticator: [enter User PIN]
# (Touch device when prompted)
# Identity added: sk-ssh-ed25519@openssh.com cardno:000F_XXXXXXXX

# 3. Verify loaded
ssh-add -L
# Should show: sk-ssh-ed25519@openssh.com ... cardno:...

# 4. Use for SSH
ssh user@server
# Will prompt for touch
```

### Listing Resident Keys

```bash
# See what resident keys are on the token
# (Requires fido2-token or similar tool)
fido2-token -L

# Or use Nitrokey tool
nitropy nk3 list-credentials
```

---

## Cleanup Procedure

### Remove from SSH Agent

```bash
# Remove all identities from current session
ssh-add -D

# Or remove specific key
ssh-add -d ~/.ssh/id_fido2_powerhouse.pub
```

### Delete from Hardware Token

```bash
# Use nitropy to delete specific credential
nitropy nk3 delete-credential [credential-id]

# Or reset all credentials (CAUTION!)
nitropy nk3 factory-reset
# WARNING: This wipes ALL credentials from token!
```

---

## Security Considerations

### Threat Model Alignment

**Resident Keys Provide:**
- ✅ Hardware-backed private key (never leaves token)
- ✅ Physical possession requirement
- ✅ No secrets in filesystem (except during discovery)
- ✅ PIN protection (optional with -O verify-required)

**Resident Keys DO NOT Provide:**
- ❌ GPG signing capability
- ❌ Email/file encryption
- ❌ Key export/backup from hardware
- ❌ Protection against compromised host (still need to trust the machine)

### Best Practices

**DO:**
- Use for specific, limited scenarios
- Label keys clearly with `-O application=ssh:NAME`
- Remove from agent after use (`ssh-add -D`)
- Require touch confirmation (default)
- Consider PIN verification for high-security access

**DON'T:**
- Store on untrusted machines (keys are cached in agent)
- Generate without resident flag (loses discovery benefit)
- Use as primary daily authentication (GPG is better)
- Forget to clean up after use on shared machines

### Comparison: GPG vs FIDO2 for SSH

| Feature | GPG Auth Subkey | FIDO2 Resident Key |
|---------|----------------|-------------------|
| **Storage** | Token (via stub) | Token (resident) |
| **Discovery** | Requires GPG setup | `ssh-add -K` anywhere |
| **Signing** | ✅ Yes | ❌ No |
| **Encryption** | ✅ Yes | ❌ No |
| **Touch Required** | ✅ Yes | ✅ Yes (default) |
| **PIN Required** | When cache expires | Optional (-O verify-required) |
| **Works Offline** | ✅ Yes | ✅ Yes |
| **Setup Complexity** | Higher (GPG agent) | Lower (direct SSH) |
| **Best For** | Daily workstation | Temporary/satellite access |

---

## Implementation Scenarios

### Scenario 1: Powerhouse Access from Capacitor

**Use Case:** Server-to-server SSH

```bash
# On powerhouse:
ssh-keygen -t ed25519-sk -O resident -O application=ssh:capacitor-access -f ~/.ssh/id_fido2_to_capacitor

# Add public key to capacitor authorized_keys
ssh-copy-id -i ~/.ssh/id_fido2_to_capacitor.pub capacitor

# Test from powerhouse
ssh capacitor

# Result: Direct hardware-backed SSH without GPG agent
```

### Scenario 2: Emergency Access from Trusted Friend's Machine

**Use Case:** Temporary access

```bash
# Previously generated key on your Nitrokey
# Stored as resident: ssh:emergency-access

# On friend's machine (trusted!):
ssh-add -K
# Enter PIN, touch device

ssh your-server
# Touch device to authenticate

# When done:
ssh-add -D
# Your keys are removed from their machine
```

### Scenario 3: Automation with Hardware Backing

**Use Case:** Scripted operations with strong authentication

```bash
# Generate key with specific constraints
ssh-keygen -t ed25519-sk -O resident -O no-touch-required \
  -O application=ssh:automation \
  -f ~/.ssh/id_fido2_auto

# Add to authorized_keys on target
# Can be used in scripts without manual touch
# (Less secure - use carefully!)
```

**WARNING:** `-O no-touch-required` removes the physical confirmation barrier. Only use for specific automation scenarios with additional controls.

---

## Troubleshooting

### Key Not Discoverable

**Symptom:** `ssh-add -K` says "No FIDO2 authenticator available"

**Solutions:**
```bash
# 1. Check token is inserted
lsusb | grep -i nitro

# 2. Check libfido2 can see it
fido2-token -L

# 3. Verify SSH has FIDO2 support
ssh -V  # Look for "with FIDO2 support"

# 4. Check for udev rules (Linux)
# User needs access to /dev/hidraw* devices
```

### Wrong PIN

**Symptom:** "Invalid PIN" after 3 attempts

**Recovery:**
- FIDO2 PIN is separate from GPG PIN
- Reset FIDO2 PIN with: `nitropy nk3 set-pin`
- Or use Admin PIN if configured

### Key Generation Fails

**Symptom:** "Key generation failed" or timeout

**Solutions:**
```bash
# 1. Touch when LED blinks
# 2. Ensure token supports Ed25519 (Nitrokey 3 does)
# 3. Try ECDSA instead:
ssh-keygen -t ecdsa-sk -O resident ...
# 4. Check token has available credential slots
nitropy nk3 status
```

---

## Future Considerations

### When to Implement

Consider implementing FIDO2 resident keys when:

1. **Operational Need Arises**
   - Specific scenario requiring hardware-backed SSH without GPG
   - Emergency access procedures needed
   - Server-to-server automation required

2. **Infrastructure Growth**
   - Adding many satellite machines
   - Need simplified access pattern
   - Team members need access without full GPG setup

3. **Security Requirements**
   - Compliance requires hardware-backed keys
   - GPG agent unacceptable for specific use case
   - Need both GPG and FIDO2 for different scenarios

### Integration with Current Model

If implemented, FIDO2 keys would:
- **Coexist** with GPG-based SSH (not replace)
- **Complement** for specific scenarios
- **Document** in server authorized_keys
- **Label** clearly for identification

---

## Related Documentation

- **Hardware Tokens:** `docs/HARDWARE-KEYS.md` - Nitrokey daily operation
- **GPG/SSH Strategy:** `docs/GPG-SSH-STRATEGY.md` - Primary authentication model
- **Deployment:** `docs/DEPLOYMENT.md` - Host provisioning
- **Security:** `docs/SECURITY.md` - Threat model and practices

---

## Reference Commands

```bash
# Generate resident key
ssh-keygen -t ed25519-sk -O resident -O application=ssh:NAME -f ~/.ssh/id_fido2_NAME

# Discover keys
ssh-add -K

# List loaded keys
ssh-add -L

# Remove all keys
ssh-add -D

# Copy to server
ssh-copy-id -i ~/.ssh/id_fido2_NAME.pub user@server

# Check token credentials
nitropy nk3 list-credentials
```

---

*Last Updated: 2026-03-04*  
*Status: Documentation Only - Not Implemented*
