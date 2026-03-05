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
  ...
}:
with lib; {
  # Hardware token management tools
  home.packages = with pkgs; [
    pynitrokey # Nitrokey 3 management (nitropy command)
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
      else pkgs.pinentry-tty;

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

      # Debug logging to diagnose SSH signing failures
      # See: https://dev.gnupg.org/T5931 (gpg-agent SSH issues with OpenSSH 8.9+)
      debug-level guru
      log-file /Users/brancengregory/.gnupg/gpg-agent.log
    '';
  };
}
