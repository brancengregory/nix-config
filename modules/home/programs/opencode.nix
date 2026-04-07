# modules/home/programs/opencode.nix
# OpenCode AI coding agent configuration
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  opencodePackage = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode;
in {
  options.programs.opencode-config = {
    enable = lib.mkEnableOption "OpenCode AI coding agent with declarative config";
  };

  config = lib.mkIf config.programs.opencode-config.enable {
    programs.opencode = {
      enable = true;
      package = opencodePackage;
      settings = lib.importJSON ./opencode/opencode.json;
      commands = {
        cc = ./opencode/commands/cc.md;
      };
    };
  };
}
