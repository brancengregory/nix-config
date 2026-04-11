{
  description = "R Development Environment Template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    ojodb = {
      url = "github:openjusticeok/ojodb";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ojodb,
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      perSystem = {
        config,
        self',
        inputs',
        system,
        ...
      }: let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            permittedInsecurePackages = [
              "electron-38.8.4"
            ];
          };
        };

        # R packages to include
        rPackages = with pkgs.rPackages; [
          # Core tidyverse
          tidyverse
          dplyr
          ggplot2
          tidyr
          readr
          purrr
          tibble
          stringr
          forcats
          lubridate

          # Development tools
          devtools
          renv
          usethis
          testthat
          roxygen2
          pkgdown
          knitr
          rmarkdown
          pkgs.rPackages.config
          logger
          here
          languageserver

          # Data tools
          arrow
          duckdb
          DBI
          RPostgres
          odbc

          # Cloud storage
          googleCloudStorageR

          # Documentation
          gt

          # Web/API
          httr2
          jsonlite

          # Utilities
          rlang
          glue
          janitor

          # Pipeline
          targets
          tarchetypes

          # Ojodb - installed from source
          (pkgs.rPackages.buildRPackage {
            name = "ojodb";
            src = ojodb;
            propagatedBuildInputs = with pkgs.rPackages; [
              dplyr
              dbplyr
              DBI
              RPostgres
              ggplot2
              pool
              rlang
              glue
              stringr
              purrr
              tidyr
              janitor
              lubridate
              hms
              fs
            ];
          })
        ];

        # R wrapper with all packages
        R = pkgs.rWrapper.override {
          packages = rPackages;
        };

        # Wrap RStudio with packages
        rstudio-wrapped = pkgs.rstudioWrapper.override {
          packages = rPackages;
        };

        # R library path for tools that need it
        rLibsPath = pkgs.lib.makeLibraryPath rPackages;
      in {
        # Development shell
        devShells.default = pkgs.mkShell {
          name = "r-dev";

          buildInputs = [
            R
            pkgs.radian
            pkgs.air-formatter
            pkgs.jarl
            pkgs.quarto
            rstudio-wrapped
          ];

          shellHook = ''
            export PATH="${R}/bin:$PATH"
            export R_LIBS_SITE="${rLibsPath}"

            echo "🚀 R Development Environment"
            echo ""
            echo "Available tools:"
            echo "  - R (with tidyverse, devtools, ojodb, etc.)"
            echo "  - radian (enhanced R REPL)"
            echo "  - air (R formatter)"
            echo "  - jarl (R linter)"
            echo "  - quarto"
            echo "  - rstudio (R IDE)"
            echo ""
            echo "Quick start:"
            echo "  R                    # Start R console"
            echo "  radian               # Enhanced R REPL"
            echo "  air format .         # Format R code"
            echo "  jarl .               # Lint R code"
            echo "  rstudio              # Launch RStudio IDE"
            echo ""
          '';
        };

        # Packages exposed for inspection
        packages = {
          inherit R;
          air = pkgs.air-formatter;
          jarl = pkgs.jarl;
        };
      };
    };
}
