{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.virtualization;
in {
  options.virtualization = {
    hypervisor = {
      enable = mkEnableOption "QEMU/KVM hypervisor (for running VMs on this host)";

      virtManager = mkOption {
        type = types.bool;
        default = true;
        description = "Enable virt-manager GUI for managing VMs";
      };

      swtpm = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Software TPM (required for Windows 11 VMs)";
      };

      spice = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SPICE protocol support (clipboard sharing, dynamic resolution)";
      };
    };

    guest = {
      enable = mkEnableOption "QEMU guest agent (for when this machine IS a VM)";

      spice = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SPICE vdagent (clipboard, dynamic resolution when running as VM)";
      };
    };
  };

  config = mkMerge [
    # Hypervisor configuration (this host runs VMs)
    (mkIf cfg.hypervisor.enable {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = cfg.hypervisor.swtpm;
        };
      };

      programs.virt-manager.enable = cfg.hypervisor.virtManager;

      users.users.brancengregory.extraGroups = ["libvirtd"];

      environment.systemPackages = with pkgs;
        []
        ++ optional cfg.hypervisor.spice spice
        ++ optional cfg.hypervisor.spice spice-gtk
        ++ optional cfg.hypervisor.spice spice-protocol
        ++ optional cfg.hypervisor.spice virt-viewer;
    })

    # Guest configuration (this host IS a VM)
    (mkIf cfg.guest.enable {
      services.qemuGuest.enable = true;
      # Note: SPICE vdagent is typically installed as a package and run via systemd user service
      # Install the package if spice support is needed for clipboard/resolution
      environment.systemPackages = mkIf cfg.guest.spice (with pkgs; [spice-vdagent]);
    })
  ];
}
