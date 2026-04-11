{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
in {
  mkHost = {
    hostname,
    system,
    user,
    builder, # nixosSystem
    homeManagerModule, # The platform-specific HM module
    sopsModule, # The platform-specific sops-nix module
    isDesktop ? false, # Whether this is a desktop (GUI) system
    extraModules ? [], # Specific features (disko)
    extraOverlays ? [], # Host-specific overlays
    extraHomeModules ? [], # Extra modules to import in home-manager
  }: let
    # NixOS only - use nixosModules.stylix
    stylixModule = inputs.stylix.nixosModules.stylix;
  in
    builder {
      inherit system;

      specialArgs = {
        inherit inputs isDesktop;
      };

      modules =
        [
          # Core Setup
          ../hosts/${hostname}/config.nix

          # Common Overlays
          {
            nixpkgs.overlays =
              [
                (import ../overlays/ojodb.nix)
              ]
              ++ extraOverlays;
          }

          # Universal Modules (Sops + Home Manager)
          sopsModule
          homeManagerModule
          stylixModule # Always import stylix for home-manager compatibility

          # Standard Home Manager Config
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {inherit inputs isDesktop;};

            # Enforced Convention with extra modules
            home-manager.users.${user} = {
              imports = [../users/${user}/home.nix] ++ extraHomeModules;
            };
          }
        ]
        ++ extraModules;
    };
}
