{ lib, ... }:
{
  imports = [
    ./backup.nix      # Already Pure Module from Phase 1
    ./monitoring.nix  # Just converted to Pure Module
    ./download.nix  # Already Pure Module
    ./git.nix         # Already Pure Module
    ./media.nix       # Already Pure Module
    ./ollama.nix      # Already Pure Module
    ./opencode.nix    # Already Pure Module
    ./storage.nix     # Already Pure Module
  ];
}
