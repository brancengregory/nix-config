{pkgs, config, ...}: let
  # Define the list of R packages we want
  my-r-packages = with pkgs.rPackages; [
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

  # Create a custom R environment that radian can definitely see
  # This builds a directory containing all the library files
  my-r-env = pkgs.buildEnv {
    name = "r-custom-env";
    paths = my-r-packages;
    pathsToLink = [ "/library" ];
  };
  
  # We still want the wrapped R for normal usage
  my-r = pkgs.rWrapper.override {
    packages = my-r-packages;
  };

in {
  home.packages = with pkgs; [
    my-r
    
    # Custom radian wrapper that explicitly sets R_LIBS_SITE
    # This bypasses any wrapper logic failure by forcing the library path
    (pkgs.writeShellScriptBin "radian" ''
      export R_LIBS_SITE="${my-r-env}/library"
      export R_BINARY="${my-r}/bin/R"
      exec ${pkgs.radian}/bin/radian "$@"
    '')
  ];

  # R Environment variables
  home.sessionVariables = {
    R_ENVIRON_USER = config.sops.secrets.renviron.path;
    # Optional: also set it globally for Rstudio or other tools
    # R_LIBS_SITE = "${my-r-env}/library"; 
  };
}