{ pkgs, ... }:

{
  home.username = "brancengregory";
  home.homeDirectory =
		if pkgs.stdenv.isLinux then "/home/brancengregory"
		else if pkgs.stdenv.isDarwin then "/Users/brancengregory"
		else throw "Unsupported OS for this home-manager configuration";

  # Prefer nixpkgs packages over Homebrew when possible
  # GUI applications should be managed via Homebrew casks in darwin.nix
  # CLI tools should generally be managed here via nixpkgs
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
    	lazygit
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

  programs.zsh = {
    enable = true;
    
    # Shell aliases
    shellAliases = {
      cl = "clear";
      v = "nvim";
      cd = "z";
      "/" = "cd /";
      "~" = "cd ~";
      ".." = "cd ..";
      "..." = "cd ../..";
      reload = "source ~/.zshrc";
      l = "ls";
      ls = "eza -al --git --icons=always";
      cat = "bat";
      tre = "eza --tree --level=3 --icons --git-ignore";
      r = "radian";
      md = "glow";
      g = "lazygit";
    } // (if pkgs.stdenv.isLinux then {
      open = "xdg-open";
      ports = "ss -tuln";
    } else {
      # macOS uses native open command
      ports = "netstat -anv | grep -E 'LISTEN|Proto'";
    });

    # History configuration
    history = {
      size = 1000000;
      save = 1000000;
      path = "$HOME/.zshistory";
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
    };

    # Additional zsh options
    historySubstringSearch.enable = true;
    
    # Custom functions and additional configuration
    initExtra = ''
      # Autocompletion
      autoload -Uz compinit && compinit

      # Custom function for reading files
      c() {
        if [[ "$1" == *.md ]]; then
          glow "$1"
        else
          bat "$1"
        fi
      }

      # History settings (additional options not covered by home-manager)
      setopt append_history           # allow multiple sessions to append to one history
      setopt bang_hist                # treat ! special during command expansion
      setopt hist_expire_dups_first   # expire duplicates first when trimming history
      setopt hist_find_no_dups        # When searching history, don't repeat
      setopt hist_reduce_blanks       # Remove extra blanks from each command added to history
      setopt hist_verify              # Don't execute immediately upon history expansion
      setopt inc_append_history       # Write to history file immediately, not when shell quits
      setopt share_history            # Share history among all sessions

      # Add history search keys
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # Add zoxide
      eval "$(zoxide init zsh)"

      # Add starship
      eval "$(starship init zsh)"

      # Start sheldon for zsh plugins
      eval "$(sheldon source)"

      # Environment variables
      export SSH_ASKPASS_REQUIRE=never
      export GPG_TTY=$(tty)
      ${if pkgs.stdenv.isLinux then ''
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"
        gpg-connect-agent updatestartuptty /bye

        # Make sure sudo works well in tmux
        if [ -n "$TMUX" ]; then
          stty sane
        fi

        export PROJ_DATA=/usr/share/proj
      '' else ''
        # macOS specific environment variables would go here if needed
      ''}

      # Conda initialization (if available)
      [ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh
      export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
    '';

    # Additional PATH entries  
    sessionVariables = {
      PATH = "$PATH:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin";
    };
  };

  home.stateVersion = "25.05";
}
