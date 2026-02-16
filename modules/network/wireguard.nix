# modules/network/wireguard.nix
# WireGuard hub-and-spoke VPN configuration
# Supports declarative key management and mesh networking

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.networking.wireguard-mesh;
  
  getNodeConfig = nodeName: {
    ip = cfg.nodes.${nodeName}.ip or "10.0.0.1";
    publicKey = cfg.nodes.${nodeName}.publicKey;
    isServer = cfg.nodes.${nodeName}.isServer or false;
    endpoint = cfg.nodes.${nodeName}.endpoint or null;
  };
  
  thisNode = getNodeConfig cfg.nodeName;
  hubNode = getNodeConfig cfg.hubNodeName;
  isHub = thisNode.isServer;
in

{
  options.networking.wireguard-mesh = {
    enable = mkEnableOption "WireGuard mesh VPN (hub-and-spoke or full mesh)";
    
    interface = mkOption {
      type = types.str;
      default = "wg0";
      description = "Name of the WireGuard interface";
    };
    
    nodeName = mkOption {
      type = types.str;
      description = "Name of this node in the mesh";
    };
    
    hubNodeName = mkOption {
      type = types.str;
      default = "capacitor";
      description = "Name of the hub node (for hub-and-spoke topology)";
    };
    
    nodes = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          ip = mkOption {
            type = types.str;
            description = "IP address of this node in the VPN";
          };
          publicKey = mkOption {
            type = types.str;
            description = "WireGuard public key of this node";
          };
          isServer = mkOption {
            type = types.bool;
            default = false;
            description = "Whether this node is the central hub/server";
          };
          endpoint = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Endpoint for this node (host:port). 
              Only needed for the hub or if using full mesh.
            '';
          };
        };
      });
      default = {};
      description = "Configuration for all nodes in the mesh";
    };
    
    port = mkOption {
      type = types.port;
      default = 51820;
      description = "Port to listen on (for hub/server nodes)";
    };
    
    dns = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "DNS servers for the VPN (defaults to hub IP if not set)";
    };
    
    privateKeyFile = mkOption {
      type = types.path;
      description = "Path to the WireGuard private key file (from sops)";
    };
    
    presharedKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to the preshared key file for extra security (optional)";
    };
    
    enableDnsServer = mkOption {
      type = types.bool;
      default = false;
      description = "Enable dnsmasq DNS server on this node (typically the hub)";
    };
  };

  config = mkIf cfg.enable {
    # Enable IP forwarding for VPN routing
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # Install WireGuard tools
    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];

    # WireGuard interface using wg-quick
    networking.wg-quick.interfaces.${cfg.interface} = {
      address = [ "${thisNode.ip}/24" ];
      dns = if cfg.dns != [ ] then cfg.dns else optional isHub hubNode.ip;
      
      listenPort = mkIf isHub cfg.port;
      privateKeyFile = cfg.privateKeyFile;
      
      peers = 
        if isHub then
          # Hub: accept connections from all spokes
          mapAttrsToList (name: node: 
            mkIf (name != cfg.hubNodeName) {
              publicKey = node.publicKey;
              allowedIPs = [ "${node.ip}/32" ];
              persistentKeepalive = 25;
            }
          ) cfg.nodes
        else
          # Spoke: connect to hub
          [
            ({
              publicKey = hubNode.publicKey;
              allowedIPs = [ "0.0.0.0/0" "::/0" ];
              endpoint = mkIf (hubNode.endpoint != null) hubNode.endpoint;
              persistentKeepalive = 25;
            } // optionalAttrs (cfg.presharedKeyFile != null) {
              presharedKeyFile = cfg.presharedKeyFile;
            })
          ];
    };

    # Firewall configuration
    networking.firewall = {
      allowedUDPPorts = mkIf isHub [ cfg.port ];
      trustedInterfaces = [ cfg.interface ];
    };

    # Ensure sops runs before WireGuard
    systemd.services."wg-quick-${cfg.interface}" = {
      after = [ "sops-nix.service" ];
      requires = [ "sops-nix.service" ];
    };

    # Optional DNS server (typically on hub)
    services.dnsmasq = mkIf (isHub && cfg.enableDnsServer) {
      enable = true;
      settings = {
        interface = cfg.interface;
        listen-address = thisNode.ip;
        address = mapAttrsToList (name: node: 
          "/${name}.vpn/${node.ip}"
        ) cfg.nodes;
        server = [ "1.1.1.1" "8.8.8.8" ];
      };
    };
  };
}
