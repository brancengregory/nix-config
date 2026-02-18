{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  
  # Helper to get the appropriate stylix module for a system type
  getStylixModule = system:
    if lib.strings.hasSuffix "darwin" system
    then inputs.stylix.darwinModules.stylix
    else inputs.stylix.nixosModules.stylix;
in
{
  mkHost = {
    hostname,
    system,
    user,
    builder,              # nixosSystem or darwinSystem
    homeManagerModule,    # The platform-specific HM module
    sopsModule,           # The platform-specific sops-nix module
    isDesktop ? false,    # Whether this is a desktop (GUI) system
    extraModules ? [],    # Specific features (disko)
    extraOverlays ? [],   # Host-specific overlays
    extraHomeModules ? [] # Extra modules to import in home-manager
  }:
  let
    # Automagic Platform Detection
    isDarwin = lib.strings.hasSuffix "darwin" system;
    isLinux = lib.strings.hasSuffix "linux" system;
    stylixModule = getStylixModule system;
  in
  builder {
    inherit system;

    specialArgs = {
      inherit inputs isDarwin isLinux isDesktop;
    };

    modules = [
      # Core Setup
      ../hosts/${hostname}/config.nix
      
      # Common Overlays
      {
        nixpkgs.overlays = [
          (import ../overlays/ojodb.nix)
        ] ++ extraOverlays;
      }

      # Universal Modules (Sops + Home Manager)
      sopsModule
      homeManagerModule
      stylixModule  # Always import stylix for home-manager compatibility

      # Standard Home Manager Config
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = { inherit inputs isDarwin isLinux isDesktop; };

        # Enforced Convention with extra modules
        home-manager.users.${user} = {
          imports = [ ../users/${user}/home.nix ] ++ extraHomeModules;
        };
      }
    ] ++ extraModules;
  };
}
