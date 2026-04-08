{
  programs.lazygit = {
    enable = true;

    settings = {
      git = {
        # Disable auto-fetch to avoid frequent remote operations that trigger
        # GPG authentication with the nitrokey hardware token
        autoFetch = false;

        # Keep auto-refresh enabled (default) so file changes are still detected
        autoRefresh = true;

        # Keep GPG process attached rather than spawning separately.
        # This is important for hardware tokens like nitrokey where the GPG
        # agent needs to communicate with the smart card.
        overrideGpg = true;

        # Prevent automatic fast-forwarding of branches after fetch.
        # Avoids unexpected remote operations that could require authentication.
        autoForwardBranches = "none";
      };
    };
  };
}
