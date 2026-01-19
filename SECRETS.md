# Secret Management Strategy for NixOS

This document outlines the strategy for managing secrets (API keys, database credentials, environment variables) in this Nix configuration repository using **sops-nix**.

## 1. Why `sops-nix`?

For a Nix-based setup, `sops-nix` is the recommended standard over `git-crypt` or `chezmoi` for the following reasons:
- **Atomic & Declarative:** Secrets are deployed alongside configuration. If a rollback happens, secrets roll back too.
- **GitOps Friendly:** Encrypted secrets are stored directly in the Git repository (YAML/JSON).
- **Integration:** It offers native NixOS and Home Manager modules, allowing you to reference secrets directly in your Nix code (e.g., `config.sops.secrets."myservice/password".path`).
- **Flexible Key Management:** It works seamlessly with Age keys and existing SSH host keys, meaning your server can decrypt its own secrets automatically without manual key distribution.

## 2. Prerequisites

You will need the following tools installed on your management machine (already added to your `home.nix` or available via `nix-shell -p sops age ssh-to-age`):
- `sops`: To edit encrypted files.
- `age`: The encryption backend.
- `ssh-to-age`: To convert SSH public keys to Age public keys.

## 3. Implementation Guide

### Step 1: Add Flake Input

Update `flake.nix` to include `sops-nix`.

```nix
inputs = {
  # ... existing inputs
  sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};

outputs = { self, sops-nix, ... }@inputs: {
  nixosConfigurations.powerhouse = nixpkgs.lib.nixosSystem {
    # ...
    modules = [
      # ...
      sops-nix.nixosModules.sops
    ];
  };
  
  # For Home Manager (macOS/Linux user configs)
  # You might need to pass `sops-nix` to your home-manager modules via `extraSpecialArgs`
};
```

### Step 2: Define Key Configuration (`.sops.yaml`)

Create a `.sops.yaml` in the root of the repository. This tells `sops` which keys to use for which files.

```yaml
# .sops.yaml
keys:
  - &user_brancen age1... # Run `age-keygen -o ~/.config/sops/age/keys.txt` to generate this if you haven't
  - &host_powerhouse age1... # Convert host SSH key: `ssh-keyscan powerhouse | ssh-to-age`
  - &host_turbine age1... 

creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
      - age:
        - *user_brancen
        - *host_powerhouse
        - *host_turbine
```

### Step 3: Create Secrets

Create a `secrets/` directory.

```bash
mkdir secrets
sops secrets/general.yaml
```

Add your secrets in the editor that opens:
```yaml
api_keys:
  openai: "sk-..."
  github: "ghp_..."
pgpass: "hostname:5432:database:username:password"
```

### Step 4: System-Level Configuration

In `modules/security/sops.nix` (or directly in host config):

```nix
{ config, pkgs, ... }: {
  sops.defaultSopsFile = ../../secrets/general.yaml;
  sops.defaultSopsFormat = "yaml";

  # Use the host's SSH key for decryption
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Example: System-wide secret
  sops.secrets."backup/restic_password" = {};
}
```

### Step 5: User-Level Configuration (Home Manager)

In `users/brancengregory/home.nix` (ensure `sops-nix.homeManagerModules.sops` is imported):

```nix
{ config, inputs, ... }: {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops.defaultSopsFile = ../../secrets/general.yaml;
  sops.age.keyFile = "/home/brancengregory/.config/sops/age/keys.txt"; # User's private key

  # Example 1: .pgpass
  sops.secrets.pgpass = {
    path = "${config.home.homeDirectory}/.pgpass";
    mode = "0600"; # Secure permissions
  };

  # Example 2: .Renviron
  sops.secrets.renviron = {
    path = "${config.home.homeDirectory}/.Renviron";
  };

  # Example 3: Shell Secrets (ZSH)
  sops.secrets.zsh_secrets = {
    # sops-nix will write the decoded content here
    path = "${config.xdg.configHome}/zsh/secrets"; 
  };
}
```

## 4. Specific Use Case: ZSH Environment Variables

To handle secrets like API keys in `.zshrc` without committing them:

1.  **Define Secret:** In `secrets/general.yaml`, add:
    ```yaml
    zsh_env: |
      export OPENAI_API_KEY="sk-..."
      export ANTHROPIC_API_KEY="sk-..."
    ```

2.  **Configure Home Manager:**
    ```nix
    sops.secrets.zsh_env = {
      path = "${config.xdg.configHome}/zsh/secrets.zsh";
    };
    ```

3.  **Source in ZSH:** Update `modules/terminal/zsh.nix`:
    ```nix
    programs.zsh.initExtra = ''
      # Source secrets if they exist
      if [ -f "$HOME/.config/zsh/secrets.zsh" ]; then
        source "$HOME/.config/zsh/secrets.zsh"
      fi
    '';
    ```

## 5. Workflow

1.  **Edit Secrets:** `sops secrets/general.yaml`
2.  **Commit:** `git add secrets/general.yaml && git commit` (The file is encrypted, safe to commit).
3.  **Apply:** `nixos-rebuild switch` or `home-manager switch`.
4.  **Rotate Keys:** If a key is compromised, update `.sops.yaml`, remove the old key, and run `sops updatekeys secrets/general.yaml`.
