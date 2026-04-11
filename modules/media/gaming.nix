{
  config,
  pkgs,
  lib,
  isDesktop,
  ...
}:
with lib; let
  cfg = config.modules.desktop.gaming;
in {
  options.modules.desktop.gaming = {
    enable =
      mkEnableOption "gaming setup"
      // {
        default = isDesktop;
      };

    gpuVendor = mkOption {
      type = types.enum ["amd" "nvidia" "intel" null];
      default = null;
      description = "GPU vendor for vendor-specific optimizations";
    };

    # Optional components (default true)
    prismLauncher.enable =
      mkEnableOption "Prism Launcher (Minecraft)"
      // {
        default = true;
      };
    mangohud.enable =
      mkEnableOption "MangoHud overlay"
      // {
        default = true;
      };
    gamescope.enable =
      mkEnableOption "Gamescope compositor"
      // {
        default = true;
      };
    protonupQt.enable =
      mkEnableOption "ProtonUp-Qt"
      // {
        default = true;
      };

    # Optional components (default false)
    lutris.enable =
      mkEnableOption "Lutris game launcher"
      // {
        default = false;
      };
    heroic.enable =
      mkEnableOption "Heroic Games Launcher (GOG/Epic)"
      // {
        default = false;
      };
    dolphin.enable =
      mkEnableOption "Dolphin emulator (GameCube/Wii)"
      // {
        default = false;
      };
    pcsx2.enable =
      mkEnableOption "PCSX2 emulator (PS2)"
      // {
        default = false;
      };
  };

  config = mkIf cfg.enable {
    # Core: Steam with 32-bit support
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    # Core: Gamemode - daemon runs but does NOTHING until game requests it
    programs.gamemode = {
      enable = true;
      settings = mkMerge [
        # Common settings
        {
          general.renice = 10;
        }
        # AMD-specific
        (mkIf (cfg.gpuVendor == "amd") {
          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
            amd_performance_level = "high";
          };
        })
        # NVIDIA-specific
        (mkIf (cfg.gpuVendor == "nvidia") {
          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
          };
        })
      ];
    };

    # Core: Controller support and 32-bit libs
    hardware.steam-hardware.enable = true;
    hardware.graphics.enable32Bit = true;

    # Core: Gaming packages (always included)
    environment.systemPackages = with pkgs;
      [
        # RetroArch frontend
        retroarch

        # RetroArch cores (declarative)
        libretro.snes9x # SNES
        libretro.mgba # Game Boy/Advance
        libretro.genesis-plus-gx # Genesis/Mega Drive
        libretro.nestopia # NES
        libretro.desmume # Nintendo DS
      ]
      # Optional packages (default true)
      ++ optionals cfg.prismLauncher.enable [prismlauncher jdk25]
      ++ optionals cfg.mangohud.enable [mangohud]
      ++ optionals cfg.gamescope.enable [gamescope]
      ++ optionals cfg.protonupQt.enable [protonup-qt]
      # Optional packages (default false)
      ++ optionals cfg.lutris.enable [lutris]
      ++ optionals cfg.heroic.enable [heroic]
      ++ optionals cfg.dolphin.enable [dolphin-emu]
      ++ optionals cfg.pcsx2.enable [pcsx2];

    # Wine is auto-installed as dependency of lutris/heroic when enabled

    # Kernel limit for games
    boot.kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };

    # Create gaming directories via home-manager (consistent with home.nix pattern)
    # Note: Steam uses default location at ~/.local/share/Steam/
    # These directories are for ROMs, Minecraft, and other non-Steam games
    home-manager.sharedModules = [
      {
        home.file."media/games/.keep" = {
          enable = true;
          text = "";
        };
        home.file."media/games/roms/.keep" = {
          enable = true;
          text = "";
        };
        home.file."media/games/minecraft/.keep" = {
          enable = true;
          text = "";
        };

        # Configure RetroArch to use system-installed cores
        programs.retroarch = {
          enable = true;
          settings = {
            libretro_directory = "/run/current-system/sw/lib/retroarch/cores";
          };
        };
      }
    ];
  };
}
