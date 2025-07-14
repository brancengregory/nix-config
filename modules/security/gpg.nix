{pkgs, ...}: {
  home.packages = with pkgs; [
    gnupg
  ];

  programs.gpg = {
    enable = true;

    # GPG configuration settings
    settings = {
      # Use modern algorithms and stronger defaults
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      cipher-algo = "AES256";
      digest-algo = "SHA512";
      cert-digest-algo = "SHA512";
      compress-algo = "ZLIB";
      disable-cipher-algo = "3DES";
      weak-digest = "SHA1";
      s2k-mode = "3";
      s2k-digest-algo = "SHA512";
      s2k-count = "65011712";

      # Display options
      fixed-list-mode = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-fingerprint = true;

      # Behavior
      require-cross-certification = true;
      no-symkey-cache = true;
      use-agent = true;
      throw-keyids = true;

      # Keyserver settings (using keys.openpgp.org as default)
      keyserver = "hkps://keys.openpgp.org";
      keyserver-options = "no-honor-keyserver-url include-revoked";
    };
  };
}
