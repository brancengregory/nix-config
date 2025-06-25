{ pkgs, ... }:

{
  imports = [
    ../common/configuration.nix
    
    # Might eventually have hardware-specific configs here too
    # ./hardware-configuration.nix 
  ];

  networking.hostName = "powerhouse";

  system.stateVersion = "25.05";
}
