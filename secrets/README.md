# Secrets Management with SOPS

This directory contains encrypted secrets managed by [SOPS](https://github.com/getsops/sops) (Secrets OPerationS).

## Setup

### 1. Install SOPS and Age

```bash
# On macOS with Homebrew
brew install sops age

# On NixOS (already installed via configuration)
# sops and age are included in the system packages
```

### 2. Generate Age Key (First Time Setup)

```bash
# Create the directory
mkdir -p ~/.config/sops/age

# Generate a new age key
age-keygen -o ~/.config/sops/age/keys.txt

# View your public key (you'll need this)
cat ~/.config/sops/age/keys.txt | grep "public key"
```

### 3. Copy the Template

```bash
cp secrets/secrets.template.yaml secrets/secrets.yaml
```

### 4. Edit and Add Your Secrets

Open `secrets/secrets.yaml` and replace all `REPLACE_ME` values with your actual secrets.

**Required for R/nix-config to work:**
- `renviron` - Your API keys (OpenAI, Census, FRED, etc.)
- `pgpass` - Database credentials (if using PostgreSQL)

**Optional:**
- `ssh.*` - SSH host keys for your servers
- `wireguard.*` - VPN configuration
- `gpg.*` - GPG keys for other machines
- `restic.*` - Backup configuration

### 5. Encrypt the File

```bash
# This will automatically encrypt using your age key
sops -e -i secrets/secrets.yaml
```

### 6. Verify It's Encrypted

```bash
# Should show encrypted values (ENC[AES256_GCM,...])
head secrets/secrets.yaml
```

### 7. Commit

```bash
git add secrets/secrets.yaml
git commit -m "Add encrypted secrets"
```

## Editing Existing Secrets

```bash
# This will decrypt, open in your $EDITOR, then re-encrypt
sops secrets/secrets.yaml
```

## Adding New Machines (Recipients)

Each machine needs its age public key added as a recipient so it can decrypt the secrets:

1. Get the age public key from the new machine:
```bash
# On the new machine:
cat ~/.config/sops/age/keys.txt | grep "public key"
```

2. Add it to `.sops.yaml` in the repo root:
```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
          - age1... # existing key
          - age1... # new machine key
```

3. Re-encrypt to add the new recipient:
```bash
sops updatekeys secrets/secrets.yaml
```

## Migrating from Chezmoi

If you're migrating from chezmoi (which used GPG encryption):

```bash
# Run the helper script
./scripts/migrate-secrets.sh

# This will:
# 1. Decrypt your chezmoi .Renviron
# 2. Extract all API keys
# 3. Show you where to paste them in secrets.yaml
```

## Troubleshooting

### "Failed to get the data key required to decrypt the SOPS file"

You need to add your age key as a recipient:

```bash
# Add your public key to the age section of the file
sops secrets/secrets.yaml
# Then add under sops:age: with a new recipient entry
```

### "No keys found in file"

Make sure you have an age key:

```bash
ls -la ~/.config/sops/age/keys.txt
# If not, generate one: age-keygen -o ~/.config/sops/age/keys.txt
```

## Security Notes

- **Never commit unencrypted secrets!** Always run `sops -e -i` before committing
- The template file (`secrets.template.yaml`) shows the structure but contains fake values - it's safe to commit
- Only commit the encrypted `secrets/secrets.yaml`
- Each machine needs its own age key to decrypt
- SOPS uses AES256-GCM for encryption
