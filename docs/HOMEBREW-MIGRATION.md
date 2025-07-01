# Homebrew to Nixpkgs Migration Summary

This document summarizes the migration of homebrew packages/casks to nixpkgs for the turbine host configuration.

## Migration Strategy

The goal was to migrate stable, well-maintained packages from homebrew casks to nixpkgs while keeping packages that work better via homebrew due to:

1. **macOS-specific integrations** - Apps that have better native macOS integration via homebrew
2. **Proprietary software** - Commercial/proprietary applications that are only available via homebrew
3. **Platform compatibility** - Packages that are not available or don't work well on macOS via nixpkgs
4. **Specialized tools** - Hardware-specific or highly specialized tools

## Packages Successfully Migrated to Nixpkgs

The following packages were successfully migrated from homebrew casks to nixpkgs in `users/brancengregory/home.nix`:

### Browsers
- **firefox** - Stable, cross-platform browser that works well via nixpkgs

## Packages Kept in Homebrew

The following packages remain in homebrew casks with detailed reasoning:

### Development Tools
- **visual-studio-code** - Better macOS integration than nixpkgs version
- **arduino-ide** - Hardware-specific tool, better via homebrew
- **android-platform-tools** - Android development, better via homebrew
- **github** - GitHub Desktop has macOS-specific features
- **podman-desktop** - Container management GUI, better via homebrew
- **postman** - API testing, proprietary, better via homebrew
- **dbeaver-community** - Database tool, Java-based, better via homebrew
- **db-browser-for-sqlite** - Specialized tool, better via homebrew
- **ngrok** - Commercial tool, better via homebrew
- **xquartz** - X11 for macOS, required via homebrew

### Browsers
- **firefox@developer-edition** - Special version, keep in homebrew
- **google-chrome** - Proprietary, better via homebrew
- **brave-browser** - Chromium-based, better macOS integration via homebrew
- **tor-browser** - Security-focused, better to use official builds

### Communication
- **slack** - Proprietary, better macOS integration via homebrew
- **discord** - Communication platform, keeping in homebrew for macOS compatibility
- **telegram** - Messaging, keeping in homebrew for macOS compatibility
- **messenger** - Meta proprietary app, homebrew only
- **microsoft-teams** - Microsoft proprietary, better via homebrew
- **signal** - Secure messaging, keeping in homebrew for macOS compatibility
- **twitch** - Gaming platform, better via homebrew

### Text Editors and IDEs
- **zed** - Modern editor with frequent updates, better via homebrew
- **ghostty** - New terminal, keep in homebrew for stability
- **kitty** - Terminal emulator, may work better via homebrew on macOS
- **iterm2** - macOS-specific terminal, homebrew only

### Productivity and Utilities
- **notion** - Proprietary productivity app, homebrew only
- **obsidian** - Note-taking, proprietary, better via homebrew
- **toggl-track** - Time tracking, proprietary, homebrew only
- **zotero** - Research tool, may have better integration via homebrew
- **activitywatch** - Activity tracking, specialized tool
- **tunnelblick** - VPN client for macOS, homebrew only
- **balenaetcher** - Hardware flashing tool, specialized

### Media and Entertainment
- **vlc** - Media player, not available on macOS via nixpkgs
- **obs** - Streaming/recording, keeping in homebrew for macOS compatibility
- **webtorrent** - BitTorrent client, specialized
- **steam** - Gaming platform, proprietary, better via homebrew
- **minecraft** - Gaming, proprietary, homebrew only
- **epic-games** - Gaming platform, proprietary, homebrew only
- **openemu** - macOS-specific emulator, homebrew only

### Science and Research
- **qgis** - GIS software, complex dependencies, better via homebrew
- **positron** - IDE, specialized, keep in homebrew
- **rstudio** - R IDE, better macOS integration via homebrew
- **miniconda** - Python distribution, better via homebrew for macOS
- **julia** - Programming language, may be better via homebrew
- **google-earth-pro** - Proprietary Google app, homebrew only
- **kiwix** - Offline wikipedia, specialized tool

### Creative Tools
- **blender** - 3D creation suite, keeping in homebrew for macOS compatibility
- **bitwig-studio** - Commercial DAW, proprietary, homebrew only
- **godot** - Game engine, keeping in homebrew for macOS compatibility
- **tic80** - Fantasy console, specialized tool

### System Tools and Utilities
- **syncthing** - File sync, keeping in homebrew for macOS compatibility
- **virtualbox** - Virtualization, requires kernel extensions, better via homebrew
- **parsec** - Remote desktop, proprietary, homebrew only
- **libreoffice** - Office suite, not available on macOS via nixpkgs
- **pgadmin4** - PostgreSQL admin, web-based, may be better via homebrew
- **mactex** - LaTeX for macOS, large specialized distribution
- **google-cloud-sdk** - Google Cloud tools, better via homebrew

### Fonts
- **font-fira-code-nerd-font**
- **font-roboto-mono**
- **font-lato**
- **font-fanwood-text**
- **font-league-spartan**

### Java Runtime Environments
- **temurin@8** - Specific Java version, better via homebrew

## Recommendations for Future Migrations

### Monitor for Potential Migrations
The following packages could potentially be migrated to nixpkgs in the future if:
- They become available on macOS via nixpkgs
- The nixpkgs versions improve in quality/integration
- The nix ecosystem changes to better support them

**Watch for future migration opportunities:**
- syncthing (when macOS support improves)
- obs-studio (if macOS compatibility improves)
- blender (if macOS support becomes stable)
- godot (if cross-platform support improves)
- libreoffice (if it becomes available on macOS)
- vlc (if it becomes available on macOS)

### Keep in Homebrew
These packages should likely **always stay in homebrew** unless the nix ecosystem fundamentally changes:

- **macOS-specific apps**: iterm2, openemu, tunnelblick
- **Proprietary commercial software**: steam, minecraft, epic-games, bitwig-studio
- **Platform integrations**: github desktop, slack, microsoft-teams
- **Hardware-specific tools**: arduino-ide, balenaetcher
- **System requirements**: xquartz, virtualbox

## Benefits of This Migration

1. **Consistency** - More packages managed through the same system (nixpkgs)
2. **Version Control** - Better version pinning and reproducibility for migrated packages
3. **Declarative Configuration** - All package management in one place
4. **Cross-Platform Support** - Packages work the same way across Linux and macOS where applicable

## Configuration Files Modified

- `users/brancengregory/home.nix` - Added migrated packages to Darwin-specific section
- `modules/darwin.nix` - Updated homebrew casks list with detailed comments about why packages remain
- `docs/HOMEBREW-MIGRATION.md` - This documentation file