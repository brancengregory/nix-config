{pkgs, ...}: {
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  programs.virt-manager.enable = true;

  users.users.brancengregory.extraGroups = ["libvirtd"];

  environment.systemPackages = with pkgs; [
    spice
    spice-gtk
    spice-protocol
    virt-viewer
    # virtio-win # ISO image, heavy, optional
    # win-spice # Windows specific? Usually just spice-gtk/virt-viewer on Linux host
  ];
}
