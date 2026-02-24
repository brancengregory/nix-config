{
  pkgs,
  config,
  ...
}: let
  # Define core R packages for global installation
  # Project-specific packages should use renv
  # Simplified list - add more as needed
  my-r-packages = with pkgs.rPackages; [
    # Tidyverse core
    tidyverse
    dplyr
    ggplot2
    tidyr
    readr
    purrr
    stringr
    lubridate

    # Development
    devtools
    renv
    usethis
    testthat
    roxygen2
    pkgs.rPackages.config
    logger
    here
    languageserver

    # Database
    DBI
    RPostgres
    odbc

    # Documentation
    knitr
    rmarkdown
    gt

    # Web/API
    httr2
    jsonlite

    # Utilities
    rlang
    glue
    janitor

    # Targets
    targets
    tarchetypes
    # qs2 temporarily removed - depends on broken RcppParallel
    # qs2

    # OJO Internal
    ojodb
  ];

  # Create a custom R environment that radian can definitely see
  # This builds a directory containing all the library files
  my-r-env = pkgs.buildEnv {
    name = "r-custom-env";
    paths = my-r-packages;
    pathsToLink = ["/library"];
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
      export R_ENVIRON_USER="${config.sops.secrets.renviron.path}"
      exec ${pkgs.radian}/bin/radian "$@"
    '')
  ];

  # R Environment variables
  home.sessionVariables = {
    R_ENVIRON_USER = config.sops.secrets.renviron.path;
    # Optional: also set it globally for Rstudio or other tools
    # R_LIBS_SITE = "${my-r-env}/library";
  };

  # .Rprofile configuration from chezmoi
  home.file.".Rprofile".text = ''
    options(
      renv.config.pak.enabled = TRUE
    )

    rlang::global_entrace()
  '';
}
