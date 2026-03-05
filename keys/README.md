# Public Keys Directory

This directory contains public key material that is safe to commit to the repository. These keys are used for verification and reference purposes only.

---

## Files

### `brancen-gregory-public.asc`

**Purpose:** GPG public key for Brancen Gregory  
**Source:** Exported from Nitrokey hardware token  
**Last Updated:** 2026-03-04

**Key Details:**
- **Name:** Brancen Gregory
- **Email:** brancengregory@gmail.com
- **Key ID:** `3D9E0666449B886D`
- **Fingerprint:** `0A8C406B92CEFC33A51EC4933D9E0666449B886D`
- **Algorithm:** Ed25519 (ECC)
- **Keyserver:** https://keys.openpgp.org

**Direct URL:**
```
https://keys.openpgp.org/vks/v1/by-fingerprint/0A8C406B92CEFC33A51EC4933D9E0666449B886D
```

**Verification:**
```bash
# Verify fingerprint matches
gpg --show-keys keys/brancen-gregory-public.asc

# Should output:
# pub   ed25519/0x3D9E0666449B886D 2026-01-01 [SCA]
#       Key fingerprint = 0A8C 406B 92CE FC33 A51E  C493 3D9E 0666 449B 886D
# uid                   Brancen Gregory <brancengregory@gmail.com>
```

**Usage:**
- Import into GPG keyring: `gpg --import keys/brancen-gregory-public.asc`
- Fetch from keyserver: `gpg --card-edit` → `fetch` → `quit`
- Verify Git commits: `git log --show-signature`

---

## Security Notes

✅ **Safe to Commit:** These are public keys only - no secret material  
✅ **Redundancy:** Backup if keyserver is unavailable  
✅ **Verification:** Always verify fingerprints before trusting  
❌ **Never Include:** Private keys, revocation certificates (keep offline)

---

## Hardware Token Reference

**Primary Token:** Nitrokey 3
- Status: Active
- Contains: GPG master key + subkeys (sign, encrypt, auth)
- User PIN: 6-8 digits
- Touch required: Yes (UIF enabled)

**Backup Token:** Nitrokey 3
- Status: Identical to primary
- Contains: Same keys as primary
- Kept offline for emergencies

**Stub Management:**
```bash
# Check if stubs exist
gpg --list-secret-keys
# Look for 'ssb>' notation (indicates stub)

# Create stubs from hardware token
gpg-connect-agent "scd serialno" "learn --force" /bye
```

---

## For More Information

- **Full Guide:** See `docs/HARDWARE-KEYS.md`
- **Deployment:** See `docs/DEPLOYMENT.md`
- **GPG/SSH Strategy:** See `docs/GPG-SSH-STRATEGY.md`
- **External Reference:** Digital Identity & Security Blueprint (2026)

---

*Last Updated: 2026-03-04*
