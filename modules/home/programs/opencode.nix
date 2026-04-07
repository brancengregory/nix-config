# modules/home/programs/opencode.nix
# OpenCode AI coding agent configuration
# Uses home-manager on Linux, manual file management on Darwin
{
  config,
  pkgs,
  lib,
  inputs,
  isLinux,
  isDarwin,
  ...
}: let
  opencodeConfigDir = "${config.xdg.configHome}/opencode";
  # Use opencode from nixpkgs-unstable for latest version
  opencodePackage = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode;
in {
  options.programs.opencode-config = {
    enable = lib.mkEnableOption "OpenCode AI coding agent with declarative config";
  };

  config = lib.mkIf config.programs.opencode-config.enable (lib.mkMerge [
    # Linux: Use home-manager's opencode module
    (lib.mkIf isLinux {
      programs.opencode = {
        enable = true;
        package = opencodePackage;
        settings = lib.importJSON ./opencode/opencode.json;
        commands = {
          cc = ./opencode/commands/cc.md;
        };
      };
    })

    # Darwin: Manual file management (Homebrew installs the package)
    (lib.mkIf isDarwin {
      # Create the config directory and files
      home.file = {
        "${opencodeConfigDir}/opencode.json".source = ./opencode/opencode.json;
        "${opencodeConfigDir}/commands/cc.md".source = ./opencode/commands/cc.md;
      };

      # Ensure .gitignore exists
      home.file."${opencodeConfigDir}/.gitignore" = {
        text = ''
          node_modules
          package.json
          bun.lock
          .gitignore
        '';
      };
    })
  ]);
}
