{pkgs, ...}: {
  home.packages = with pkgs; [
    (rWrapper.override {
      packages = with rPackages; [
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
    })
    radian
  ];

  # Force radian to use the wrapped R
  home.sessionVariables = {
    R_BINARY = "${pkgs.R}/bin/R";
  };
}
