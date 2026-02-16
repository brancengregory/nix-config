# modules/home/gpg.nix
# Home-manager GPG client configuration
# User-level GPG settings, agent, and SSH support

{ config, pkgs, lib, ... }:

with lib;

{
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

    # Platform-optimized pinentry
    pinentry.package =
      if pkgs.stdenv.isLinux
      then pkgs.pinentry-curses
      else pkgs.pinentry-curses;

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
