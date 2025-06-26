{ pkgs, ... }:

{
	nix.enable = true;

	# Set the primary user for user-specific system settings
	system.primaryUser = "brancengregory";

	# Set system defaults
	system.defaults.screencapture.location = "~/Pictures/Screenshots";

	# Ensure nix-daemon is running
	nix.package = pkgs.nix;

	# Definte the user account for nix-darwin
	users.users.brancengregory = {
		home = "/Users/brancengregory";
	};
}
