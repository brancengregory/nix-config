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
    radian
  ];

  # Force radian to use the wrapped R
  home.sessionVariables = {
    R_BINARY = "${my-r}/bin/R";
    R_ENVIRON_USER = config.sops.secrets.renviron.path;
  };
}
