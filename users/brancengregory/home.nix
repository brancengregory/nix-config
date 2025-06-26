{ pkgs, ... }:

{
  home.username = "brancengregory";
  home.homeDirectory =
		if pkgs.stdenv.isLinux then "/home/brancengregory"
		else if pkgs.stdenv.isDarwin then "/Users/brancengregory"
		else throw "Unsupported OS for this home-manager configuration";

  home.packages = with pkgs;
		[
    	bat
    	eza
    	fd
    	fzf
    	# ghostty maybe
    	git
    	glow
    	htop
    	hwatch
    	jaq
    	jnv
    	# lazygit maybe
    	# lazysql maybe
    	neovim
    	nerd-fonts.fira-code
    	nmap
    	# ollama maybe
    	# opencode maybe
    	procs
    	# r maybe
    	# radian maybe
    	ripgrep
    	scc
    	sesh
    	sheldon
    	sshs
    	starship
    	tealdeer
    	tmux
    	wireguard-tools
    	zoxide
    	zsh
    	zsh-autosuggestions
    	zsh-completions
    	zsh-fast-syntax-highlighting
  	]
		++ (if pkgs.stdenv.isLinux then
			[
				# Linux specific packages
				sudo
			]
		else if pkgs.stdenv.isDarwin then
			[
				# Mac specific packages
				# mas-cli maybe
			]
		else
			throw "Unsupported OS for this home-manager configuration"
		);

  fonts.fontconfig.enable = true;

  programs.git = {
    enable = true;
    userName = "Brancen Gregory";
    userEmail = "brancengregory@gmail.com";
  };

  home.stateVersion = "25.05";
}
