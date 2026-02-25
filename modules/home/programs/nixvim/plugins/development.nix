# Development Plugins (Rust, R, Comments)
{ pkgs, ... }: {
  programs.nixvim = {
    plugins = {
      # Rust tools - rustaceanvim (modern standard)
      rustaceanvim = {
        enable = true;
        settings = {
          server = {
            enable = true;
            default_settings = {
              rust-analyzer = {
                cargo = {
                  allFeatures = true;
                };
                checkOnSave = true;
                check = {
                  command = "clippy";
                };
              };
            };
          };
        };
      };

      # Comment.nvim - Smart commenting
      comment = {
        enable = true;
        settings = {
          mappings = {
            basic = true;
            extra = true;
          };
        };
      };

      # R.nvim - R development environment (v0.99.3)
      # Built from source since not available in nixvim modules
    };

    # Extra plugins built from source
    extraPlugins = with pkgs.vimUtils; [
      (buildVimPlugin {
        name = "r-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "R-nvim";
          repo = "R.nvim";
          rev = "v0.99.3";
          sha256 = "sha256-oQSHHu6filJkAyH94yEvyTVuxA+5MU2dMOEAnsIjJKQ=";
        };
        buildInputs = [ 
          pkgs.which
          pkgs.zip
        ];
      })
    ];
  };
}
