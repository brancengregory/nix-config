{pkgs, config, ...}: let
  my-r = pkgs.rWrapper.override {
    packages = with pkgs.rPackages; [
      # Core
      cli
      devtools
      dplyr
      fs
      ggplot2
      glue
      lubridate
      tibble
      readr
      renv
      rix
      rlang
      scales
      stringr
      targets
      usethis
      readxl
      janitor
      tidymodels

      # Database
      DBI
      RPostgres
      RSQLite
      duckdb
      arrow

      # Production & Parallelism
      crew
      mirai
      plumber
      httr2
      shiny
      bslib

      # Custom Overlay
      ojodb
    ];
  };
in {
  home.packages = with pkgs; [
    my-r
    # Wrap radian to explicitly use our wrapped R
    (pkgs.writeShellScriptBin "radian" ''
      export R_BINARY="${my-r}/bin/R"
      exec ${pkgs.radian}/bin/radian "$@"
    '')
  ];

  # R Environment variables
  home.sessionVariables = {
    R_ENVIRON_USER = config.sops.secrets.renviron.path;
  };
}
