# Restic Backup Configuration

This project uses [Restic](https://restic.net/) for backups, configured declaratively via NixOS. The configuration expects specific credential files to exist on the system to authenticate with the backup repository (e.g., Google Cloud Storage).

## 1. Quick Start (Manual Setup)

For the service to start correctly, you need to manually create the secret files on the target machine.

### Step 1: Create the secrets directory
```bash
sudo mkdir -p /etc/nixos/secrets
sudo chmod 700 /etc/nixos/secrets
```

### Step 2: Create the Password File
This file contains **only** the repository password.

```bash
sudo touch /etc/nixos/secrets/restic-password
sudo chmod 600 /etc/nixos/secrets/restic-password
sudo nano /etc/nixos/secrets/restic-password
# Paste your repository password (no newlines)
```

### Step 3: Create the Environment File
This file contains environment variables for the backend (e.g., GCS credentials).

```bash
sudo touch /etc/nixos/secrets/restic-env
sudo chmod 600 /etc/nixos/secrets/restic-env
sudo nano /etc/nixos/secrets/restic-env
```

**Content for Google Cloud Storage:**
```env
GOOGLE_PROJECT_ID=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=/etc/nixos/secrets/gcs-key.json
```

### Step 4: GCS Key File (If using GCS)
If you defined `GOOGLE_APPLICATION_CREDENTIALS` above, you need that file too.

```bash
# Copy your JSON key file to the server
sudo cp /path/to/your-key.json /etc/nixos/secrets/gcs-key.json
sudo chmod 600 /etc/nixos/secrets/gcs-key.json
```

### Step 5: Test the Service
Rebuild your system or restart the service:
```bash
sudo systemctl restart restic-backups-daily-home
sudo systemctl status restic-backups-daily-home
```

---

## 2. Production (Recommended: sops-nix)

For a fully declarative and secure production setup, avoid manually placing files. Instead, use **sops-nix** to encrypt secrets within this git repository.

1.  **Install sops**: Add `sops` to your environment.
2.  **Generate Keys**: Create an SSH or Age key for your host.
3.  **Encrypt**: Create a `secrets.yaml` file encrypted with that key containing the file contents.
4.  **Configure NixOS**: Use `sops-nix` module to decrypt `secrets.yaml` at runtime and place the files in `/run/secrets/`.

*Example sops-nix config:*
```nix
sops.secrets.restic-password = {};
sops.secrets.restic-env = {};

services.restic.backups.daily-home = {
  passwordFile = config.sops.secrets.restic-password.path;
  environmentFile = config.sops.secrets.restic-env.path;
};
```
