{ pkgs, ... }: {
  home.packages = with pkgs; [
    openssh
  ];

  # SSH configuration with GPG agent integration
  programs.ssh = {
    enable = true;

    # Global SSH client configuration
    extraConfig = ''
      # Security settings
      Protocol 2
      HashKnownHosts yes
      VisualHostKey yes
      PasswordAuthentication no
      ChallengeResponseAuthentication no
      StrictHostKeyChecking ask
      VerifyHostKeyDNS yes
      ForwardAgent no
      ForwardX11 no
      ForwardX11Trusted no
      ServerAliveInterval 300
      ServerAliveCountMax 2
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512
      KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
      HostKeyAlgorithms ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,rsa-sha2-256,rsa-sha2-512
      PubkeyAcceptedKeyTypes ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,rsa-sha2-256,rsa-sha2-512
    '';

    # Common host configurations
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        # Use GPG SSH key for GitHub
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identitiesOnly = true;
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      # Template for personal servers
      "*.local" = {
        user = "brancengregory";
        identitiesOnly = true;
      };
    };
  };
}
