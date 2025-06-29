{ pkgs, ... }:

{
	nix.enable = true;

	system = {
		# Set the primary user for user-specific system settings
		primaryUser = "brancengregory";

		defaults = {
			NSGlobalDomain = {
				AppleInterfaceStyle = Dark;
				ApplePressAndHoldEnabled = true;
				AppleScrollerPagingBehavior = true;
				AppleShowAllExtensions = true;
				AppleShowAllFiles = false;
				AppleShowScrollBars = "WhenScrolling";
				# InitialKeyRepeat = ; # Add value
				# KeyRepeat = ; # Add value
				NSAutomaticCapitalizationEnabled = false;
				NSAutomaticDashSubstitutionEnabled = false;
				NSAutomaticInlinePredictionEnabled = false;
				NSAutomaticPeriodSubstitutionEnabled = false;
				NSAutomaticQuoteSubstitutionEnabled = false;
				NSAutomaticSpellingCorrectionEnabled = false;
				NSDisableAutomaticTermination = true;
				NSDocumentSaveNewDocumentsToCloud = false;
				_HIHideMenuBar = true;
				"com.apple.sound.beep.feedback" = 0;
				"com.apple.sound.beep.volume" = 0;
				"com.apple.swipescrolldirection" = false;
				# "com.apple.trackpad.scaling" = ; # Add value
			};
			controlcenter = {
				AirDrop = 24;
				BatteryShowPercentage = true;
				Bluetooth = true;
				Display = true;
				FocusModes = true;
				NowPlaying = true;
				Sound = true;
			};
			dock = {
				appswitcher-all-displays = true;
				autohide = true;
				persistent-others = [
					"~/Downloads"
				];
				show-recents = false;
				wvous-bl-corner = 1;
				wvous-br-corner = 1;
				wvous-tl-corner = 1;
				wvous-tr-corner = 1;
			};
			finder = {
				AppleShowAllExtensions = true;
				AppleShowAllFiles = false;
				FXEnableExtensionChangeWarning = false;
				FXPreferredViewStyle = "Nlsv";
				NewWindowTarget = "Home";
				ShowHardDrivesOnDesktop = true;
				ShowPathbar = true;
				ShowStatusBar = true;
				_FXShowPosixPathInTitle = true;
			};
			loginwindow = {
				GuestEnabled = false;
			};
			menuExtraClock = {
				ShowAMPM = true;
				ShowDate = 1;
			};
			screencapture = {
				location = "~/Downloads";
			};
		};
	};

	# Ensure nix-daemon is running
	nix.package = pkgs.nix;

	# Define the user account for nix-darwin
	users.users.brancengregory = {
		home = "/Users/brancengregory";
	};
}
