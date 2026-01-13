{pkgs, ...}: {
  home.packages = with pkgs; [
    gnupg
    openssh
  ];

  # Streamlined GPG configuration with essential security settings
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

  # Streamlined SSH configuration with balanced security
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraConfig = ''
      # Core security settings
      Protocol 2
      PasswordAuthentication no
      ChallengeResponseAuthentication no
      StrictHostKeyChecking ask
      HashKnownHosts yes
      ForwardAgent no
      ForwardX11 no
      ServerAliveInterval 300
      ServerAliveCountMax 2

      # Modern cryptography (essential algorithms only)
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr
      MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
      KexAlgorithms curve25519-sha256,diffie-hellman-group16-sha512
      HostKeyAlgorithms ssh-ed25519,rsa-sha2-256,rsa-sha2-512
      PubkeyAcceptedKeyTypes ssh-ed25519,rsa-sha2-256,rsa-sha2-512
    '';

    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        extraOptions = { PreferredAuthentications = "publickey"; };
      };
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identitiesOnly = true;
        extraOptions = { PreferredAuthentications = "publickey"; };
      };
      "*.local" = {
        user = "brancengregory";
        identitiesOnly = true;
      };
      "*" = {
        # Catch-all for global defaults if needed
      };
    };
  };

  # Optimized GPG Agent configuration
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableScDaemon = true;

    # Platform-optimized pinentry with fallback to curses
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
