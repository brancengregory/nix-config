# DEPRECATED: Plasma configuration moved to system level
#
# Plasma configuration has been consolidated into modules/desktop/plasma.nix
# and is now applied via home-manager.sharedModules at the system level.
#
# To enable Plasma, use in your host configuration:
#   desktop.plasma.enable = true;
#
# This applies both the system-level Plasma 6 desktop AND plasma-manager
# user configuration automatically.
#
# Options available:
#   desktop.plasma.lookAndFeel - Theme (default: "org.kde.breezedark.desktop")
#   desktop.plasma.virtualDesktops - Number of virtual desktops (default: 1)
