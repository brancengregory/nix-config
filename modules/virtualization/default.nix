{ lib, ... }:
{
  imports = [
    ./podman.nix
    ./qemu.nix
  ];
}
