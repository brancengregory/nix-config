{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
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
    extraModules ? [],    # Specific features (stylix, disko)
    extraOverlays ? [],   # Host-specific overlays
    extraHomeModules ? [] # Extra modules to import in home-manager
  }:
  let
    # Automagic Platform Detection
    isDarwin = lib.strings.hasSuffix "darwin" system;
    isLinux = lib.strings.hasSuffix "linux" system;
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

      # Standard Home Manager Config
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = { inherit inputs isDarwin isLinux isDesktop; };
        home-manager.sharedModules = [
          { stylix.enableReleaseChecks = false; }
        ];

        # Enforced Convention with extra modules
        home-manager.users.${user} = {
          imports = [ ../users/${user}/home.nix ] ++ extraHomeModules;
        };
      }
    ] ++ extraModules;
  };
}
