{ pkgs, ... }: {
  # System-level WireGuard support
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  # systemd-networkd configuration
  systemd.network.networks = {
    "20-wired" = {
      matchConfig.Name = "enp7s0";
      networkConfig.DHCP = "yes";
    };
    "30-wg0" = {
      matchConfig.Name = "wg0";
      networkConfig = {
        Address = "10.0.0.1/24";
        IPMasquerade = "both";
      };
      linkConfig.MTU = "1280";
    };
  };

  # Note: Actual interface configuration (peers, keys) is typically 
  # handled in host-specific config or via secrets.
  # 
  # Example template for manual setup:
  # networking.wg-quick.interfaces.wg0 = {
  #   autostart = false; # Set to true to start on boot
  #   address = [ "10.0.0.2/24" ];
  #   dns = [ "1.1.1.1" ];
  #   privateKeyFile = "/etc/nixos/secrets/wg-private";
  #
  #   peers = [
  #     {
  #       publicKey = "{server-public-key}";
  #       allowedIPs = [ "0.0.0.0/0" ];
  #       endpoint = "{server-ip}:51820";
  #       persistentKeepalive = 25;
  #     }
  #   ];
  # };
}