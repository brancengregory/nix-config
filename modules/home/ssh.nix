# modules/home/ssh.nix
# Home-manager SSH client configuration
# User-level SSH client settings and host configurations
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  # Install SSH client
  home.packages = with pkgs; [
    openssh
  ];

  # SSH client configuration
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
      "*" = {};
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
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
      "*.local" = {
        user = "brancengregory";
        identitiesOnly = true;
      };
    };
  };
}
