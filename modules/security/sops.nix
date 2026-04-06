{inputs, ...}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";

  # Use the host's SSH key for decryption
  # This corresponds to the host_powerhouse key in .sops.yaml
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  # Restic Backup Secrets
  sops.secrets."restic/password" = {};
  sops.secrets."restic/env" = {};
}
