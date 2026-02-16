# modules/security/ssh.nix
# SSH configuration including declarative host key management
# Deploys pre-generated host keys from sops secrets
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.openssh.hostKeysDeclarative;
in {
  options.services.openssh.hostKeysDeclarative = {
    enable = mkEnableOption "declarative SSH host key management";

    ed25519 = {
      privateKeyFile = mkOption {
        type = types.path;
        description = "Path to Ed25519 private key (from sops)";
      };

      publicKeyFile = mkOption {
        type = types.path;
        description = "Path to Ed25519 public key (from sops)";
      };
    };

    rsa = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          privateKeyFile = mkOption {
            type = types.path;
            description = "Path to RSA private key (from sops)";
          };

          publicKeyFile = mkOption {
            type = types.path;
            description = "Path to RSA public key (from sops)";
          };

          bits = mkOption {
            type = types.int;
            default = 4096;
            description = "RSA key size in bits";
          };
        };
      });
      default = null;
      description = ''
        Optional RSA host key. If null, only Ed25519 key will be used.
        RSA is mostly for compatibility with older clients.
      '';
    };

    extraAuthorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Additional authorized keys that can access this host.
        Useful for emergency access or other admins.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Ensure OpenSSH is enabled
    services.openssh = {
      enable = true;

      # Use our declarative keys instead of auto-generated ones
      hostKeys = mkForce ([
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ]
        ++ optionals (cfg.rsa != null) [
          {
            path = "/etc/ssh/ssh_host_rsa_key";
            type = "rsa";
            bits = cfg.rsa.bits;
          }
        ]);

      # SSH hardening is configured in modules/os/nixos.nix and modules/security/default.nix
    };

    # Deploy keys via activation script
    system.activationScripts.ssh-host-keys = {
      deps = [];
      text = ''
        #!/usr/bin/env bash
        set -e

        echo "Deploying SSH host keys..."

        # Ed25519 key
        if [ -f "${cfg.ed25519.privateKeyFile}" ]; then
          install -m 600 "${cfg.ed25519.privateKeyFile}" /etc/ssh/ssh_host_ed25519_key
          echo "Ed25519 private key deployed"
        else
          echo "WARNING: Ed25519 private key not found at ${cfg.ed25519.privateKeyFile}"
        fi

        if [ -f "${cfg.ed25519.publicKeyFile}" ]; then
          install -m 644 "${cfg.ed25519.publicKeyFile}" /etc/ssh/ssh_host_ed25519_key.pub
          echo "Ed25519 public key deployed"
        fi

        # RSA key (if configured)
        ${optionalString (cfg.rsa != null) ''
          if [ -f "${cfg.rsa.privateKeyFile}" ]; then
            install -m 600 "${cfg.rsa.privateKeyFile}" /etc/ssh/ssh_host_rsa_key
            echo "RSA private key deployed"
          else
            echo "WARNING: RSA private key not found at ${cfg.rsa.privateKeyFile}"
          fi

          if [ -f "${cfg.rsa.publicKeyFile}" ]; then
            install -m 644 "${cfg.rsa.publicKeyFile}" /etc/ssh/ssh_host_rsa_key.pub
            echo "RSA public key deployed"
          fi
        ''}

        # Set proper ownership
        chown root:root /etc/ssh/ssh_host_* 2>/dev/null || true

        echo "SSH host keys deployed"
      '';
    };

    # Authorized keys for users
    users.users.brancengregory.openssh.authorizedKeys.keys = cfg.extraAuthorizedKeys;

    # Ensure sops runs before SSH needs the keys
    systemd.services.sshd = {
      after = ["sops-nix.service"];
      requires = ["sops-nix.service"];
    };
  };
}
