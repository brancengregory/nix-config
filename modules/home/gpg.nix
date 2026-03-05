# modules/home/gpg.nix
# Home-manager GPG client configuration
# User-level GPG settings, agent, and SSH support
#
# NOTE: GPG secret keys live on Nitrokey hardware tokens.
# Stubs are created automatically when the token is first used.
# See docs/HARDWARE-KEYS.md for details.
{
  pkgs,
  lib,
  isLinux,
  isDarwin,
  ...
}:
with lib; let
  # Smart pinentry wrapper for macOS that selects appropriate pinentry
  # based on session type (local GUI vs SSH)
  # Named 'pinentry' to match what gpg-agent expects
  pinentry-darwin-wrapper = pkgs.writeShellScriptBin "pinentry" ''
    #!/usr/bin/env bash
    # Smart pinentry selector for macOS
    # Uses pinentry-mac for local GUI sessions (works with lazygit)
    # Uses pinentry-tty for SSH sessions
    
    # Check if PINENTRY_USER_DATA contains USE_TTY=1 (set for SSH sessions)
    case "''${PINENTRY_USER_DATA:-}" in
      *USE_TTY=1*)
        # pinentry-tty provides bin/pinentry
        exec ${pkgs.pinentry-tty}/bin/pinentry "$@"
        ;;
    esac
    
    # Default: use GUI pinentry for local sessions
    # The macOS package specifically names its binary pinentry-mac
    exec ${pkgs.pinentry_mac}/bin/pinentry-mac "$@"
  '';
in {
  # Hardware token management tools
  home.packages = with pkgs; [
    pynitrokey # Nitrokey 3 management (nitropy command)
  ] ++ lib.optionals isDarwin [
    pinentry-darwin-wrapper
    pinentry_mac
    # pinentry-tty is not included here - wrapper references it directly via store path
  ] ++ lib.optionals isLinux [
    pinentry-curses
  ];

  # GPG client settings
  programs.gpg = {
    enable = true;
    settings = {
      # Modern algorithms (essential only)
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      cipher-algo = "AES256";
      digest-algo = "SHA512";
      cert-digest-algo = "SHA512";

      # Disable weak algorithms
      disable-cipher-algo = "3DES";
      weak-digest = "SHA1";

      # Essential display and behavior options
      keyid-format = "0xlong";
      with-fingerprint = true;
      use-agent = true;

      # Keyserver settings
      keyserver = "hkps://keys.openpgp.org";
      keyserver-options = "no-honor-keyserver-url";
    };
  };

  # GPG Agent configuration
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableScDaemon = true;

    pinentry.package =
      if isLinux
      then pkgs.pinentry-curses
      else pinentry-darwin-wrapper;

    # Optimized cache settings
    defaultCacheTtl = 28800; # 8 hours
    defaultCacheTtlSsh = 28800; # 8 hours
    maxCacheTtl = 86400; # 24 hours
    maxCacheTtlSsh = 86400; # 24 hours

    extraConfig = ''
      allow-preset-passphrase
      allow-loopback-pinentry

      # Basic passphrase constraints
      min-passphrase-len 12
      min-passphrase-nonalpha 2
    '';
  };
}
