# modules/security/gpg.nix
# GPG hardware token support configuration
# 
# NOTE: This module does NOT import GPG secret keys.
# Secret keys live exclusively on Nitrokey 3 hardware tokens.
# Hosts use lightweight "stubs" that reference keys on hardware.
# See docs/HARDWARE-KEYS.md and docs/GPG-SSH-STRATEGY.md

{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.security.gpg;
in {
  options.security.gpg = {
    enable = mkEnableOption "GPG hardware token support";

    user = mkOption {
      type = types.str;
      default = "brancengregory";
      description = "User to configure GPG for";
    };

    # Optional: Import public keys for signature verification
    # Note: Secret keys are on hardware, not imported
    publicKeysFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Optional path to armored public keys file for signature verification.
        Secret keys are NOT imported - they remain on the hardware token.
        Public keys can also be fetched from keys.openpgp.org via `gpg --card-edit` -> `fetch`
      '';
    };

    trustLevel = mkOption {
      type = types.enum [1 2 3 4 5];
      default = 5;
      description = ''
        Trust level for imported public keys:
        1 = I don't know
        2 = I do NOT trust
        3 = I trust marginally
        4 = I trust fully
        5 = I trust ultimately
      '';
    };

    enableSSH = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GPG agent for SSH authentication (via hardware token)";
    };
  };

  config = mkIf cfg.enable {
    # Ensure GPG and smart card support are installed system-wide
    environment.systemPackages = with pkgs; [
      gnupg
      pinentry-curses
    ];

    # Enable pcscd for smart card access (required for Nitrokey)
    services.pcscd.enable = true;

    # Optional: Import public keys for signature verification
    # Stubs for hardware keys are created automatically when token is used
    system.activationScripts.gpg-public-keys = mkIf (cfg.publicKeysFile != null) {
      deps = ["users" "groups"];
      text = ''
        #!/usr/bin/env bash
        set -e

        USER="${cfg.user}"
        USER_HOME="/home/$USER"
        GNUPGHOME="$USER_HOME/.gnupg"

        # Create GPG directory if it doesn't exist
        if [ ! -d "$GNUPGHOME" ]; then
          mkdir -p "$GNUPGHOME"
          chmod 700 "$GNUPGHOME"
          chown "$USER:users" "$GNUPGHOME"
        fi

        # Import public keys only (for signature verification)
        if [ -f "${cfg.publicKeysFile}" ]; then
          if ! ${pkgs.gnupg}/bin/gpg --homedir "$GNUPGHOME" --list-keys 2>/dev/null | grep -q "0A8C406B92CEFC33A51EC4933D9E0666449B886D"; then
            echo "Importing GPG public keys for $USER..."
            ${pkgs.gnupg}/bin/gpg --homedir "$GNUPGHOME" --batch --import "${cfg.publicKeysFile}" 2>/dev/null || true
            
            # Set trust level on imported keys
            MASTER_FPR=$(${pkgs.gnupg}/bin/gpg --homedir "$GNUPGHOME" --list-keys --with-colons 2>/dev/null | grep fpr | head -1 | cut -d: -f10 || echo "")
            if [ -n "$MASTER_FPR" ]; then
              echo "Setting trust level ${toString cfg.trustLevel} on $MASTER_FPR"
              echo -e "${toString cfg.trustLevel}\ny\n" | ${pkgs.gnupg}/bin/gpg --homedir "$GNUPGHOME" --command-fd 0 --edit-key "$MASTER_FPR" trust quit 2>/dev/null || true
            fi
          else
            echo "GPG public keys already imported for $USER"
          fi
        fi

        # Fix permissions
        chown -R "$USER:users" "$GNUPGHOME" 2>/dev/null || true
        chmod -R u+rwX,go-rwx "$GNUPGHOME" 2>/dev/null || true
      '';
    };

    # Note: Secret keys are NOT imported - they remain on hardware token
    # Stubs are created automatically when:
    # 1. User inserts Nitrokey
    # 2. Runs: gpg --card-edit -> fetch -> quit
    # 3. Or runs: gpg-connect-agent "scd serialno" "learn --force" /bye
    # 4. Or simply uses GPG (git commit, ssh, etc.)

    # Documentation reference
    warnings = optional cfg.enable 
      "GPG secret keys are stored on hardware tokens, not imported. " +
      "See docs/HARDWARE-KEYS.md for provisioning instructions.";
  };
}
