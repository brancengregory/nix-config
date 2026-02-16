# modules/security/gpg.nix
# GPG configuration including declarative key import from sops secrets
# Imports master key with subkeys for SSH authentication

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.security.gpg;
in

{
  options.security.gpg = {
    enable = mkEnableOption "declarative GPG key import";
    
    user = mkOption {
      type = types.str;
      default = "brancengregory";
      description = "User to import keys for";
    };
    
    secretKeysFile = mkOption {
      type = types.path;
      description = "Path to armored secret keys file (from sops)";
    };
    
    publicKeysFile = mkOption {
      type = types.path;
      description = "Path to armored public keys file (from sops)";
    };
    
    trustLevel = mkOption {
      type = types.enum [ 1 2 3 4 5 ];
      default = 5;
      description = ''
        Trust level for imported keys:
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
      description = "Enable GPG agent for SSH authentication";
    };
  };

  config = mkIf cfg.enable {
    # Ensure GPG and pinentry are installed system-wide
    environment.systemPackages = with pkgs; [
      gnupg
      pinentry-curses
    ];

    # Import keys via activation script
    system.activationScripts.gpg-import = {
      deps = [ "users" "groups" ];
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
        
        # Check if keys are already imported
        if ${pkgs.gnupg}/bin/gpg --homedir "$GNUPGHOME" --list-keys 2>/dev/null | grep -q "pub"; then
          echo "GPG keys already imported for $USER"
          exit 0
        fi
        
        echo "Importing GPG keys for $USER..."
        
        # Import secret keys
        if [ -f "${cfg.secretKeysFile}" ]; then
          ${pkgs.gnupg}/bin/gpg --homedir "$GNUPGHOME" --batch --import "${cfg.secretKeysFile}" 2>/dev/null || true
          echo "Secret keys imported"
        fi
        
        # Import public keys
        if [ -f "${cfg.publicKeysFile}" ]; then
          ${pkgs.gnupg}/bin/gpg --homedir "$GNUPGHOME" --batch --import "${cfg.publicKeysFile}" 2>/dev/null || true
          echo "Public keys imported"
        fi
        
        # Set trust level on imported keys
        MASTER_FPR=$(${pkgs.gnupg}/bin/gpg --homedir "$GNUPGHOME" --list-keys --with-colons 2>/dev/null | grep fpr | head -1 | cut -d: -f10 || echo "")
        
        if [ -n "$MASTER_FPR" ]; then
          echo "Setting trust level ${toString cfg.trustLevel} on $MASTER_FPR"
          echo -e "5\ny\n" | ${pkgs.gnupg}/bin/gpg --homedir "$GNUPGHOME" --command-fd 0 --edit-key "$MASTER_FPR" trust quit 2>/dev/null || true
        fi
        
        # Fix permissions
        chown -R "$USER:users" "$GNUPGHOME"
        chmod -R u+rwX,go-rwx "$GNUPGHOME"
        
        echo "GPG keys imported successfully"
      '';
    };

  };
}
