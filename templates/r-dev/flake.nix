{
  description = "R Development Environment Template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    ojodb = {
      url = "github:openjusticeok/ojodb";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ojodb }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          # R packages to include
          rPackages = with pkgs.rPackages; [
            # Core tidyverse
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
            usethis
            testthat
            roxygen2
            pkgdown
            knitr
            rmarkdown

            # Data tools
            arrow
            duckdb
            DBI
            
            # Cloud storage
            googleCloudStorageR

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
        in
        {
          # Development shell
          devShells.default = pkgs.mkShell {
            name = "r-dev";

            buildInputs = [
              R
              pkgs.air-formatter
              pkgs.jarl
              pkgs.quarto
            ];

            shellHook = ''
              echo "🚀 R Development Environment"
              echo ""
              echo "Available tools:"
              echo "  - R (with tidyverse, devtools, ojodb, etc.)"
              echo "  - air (R formatter)"
              echo "  - jarl (R linter)"
              echo "  - quarto"
              echo ""
              echo "Quick start:"
              echo "  R                    # Start R console"
              echo "  air format .         # Format R code"
              echo "  jarl .               # Lint R code"
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
