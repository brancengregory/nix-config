final: prev: {
  rPackages = prev.rPackages.override {
    overrides = {
      ojodb = prev.rPackages.buildRPackage {
        name = "ojodb";
        src = final.fetchFromGitHub {
          owner = "openjusticeok";
          repo = "ojodb";
          rev = "v2.11.0";
          sha256 = "sha256-skH4+WV31l2AKsurZOlzLLZLR0R8JGddJMLWAp65IYQ=";
        };
        propagatedBuildInputs = with final.rPackages; [
          DBI
          RPostgres
          dplyr
          dbplyr
          ggplot2
          pool
          magrittr
          rlang
          stringr
          purrr
        ];
      };
    };
  };
}
