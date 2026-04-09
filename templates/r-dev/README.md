# R Development Environment Template

A comprehensive R development environment using Nix flakes and flake-parts.

## Usage

### Initialize from this template

```bash
nix flake init -t /path/to/nix-config#r-dev
```

Or with this repository:

```bash
nix flake init -t github:brancengregory/nix-config#r-dev
```

### Enter the development shell

```bash
nix develop
```

Or with direnv:

```bash
echo "use flake" > .envrc
direnv allow
```

## Included Tools

### R Environment
- **R** with comprehensive packages:
  - **tidyverse**: dplyr, ggplot2, tidyr, readr, purrr, tibble, stringr, forcats, lubridate
  - **Development**: devtools, usethis, testthat, roxygen2, pkgdown, knitr, rmarkdown
  - **Data**: arrow, duckdb, DBI
  - **Cloud**: googleCloudStorageR
  - **OJO**: ojodb (Oklahoma Justice Data)

### CLI Tools
- **air** - Extremely fast R code formatter
- **jarl** - Just Another R Linter
- **quarto** - Scientific and technical publishing system

## Tool Usage

### air (Formatter)

```bash
# Format all R files in current directory
air format .

# Check formatting without modifying files
air format . --check
```

### jarl (Linter)

```bash
# Lint all R files in current directory
jarl .

# Lint with specific output format
jarl . --output-format json

# Show statistics instead of detailed violations
jarl . --statistics
```

### R

```bash
# Start R console
R

# Start R with ojodb loaded
R -e "library(ojodb)"
```

## Customization

### Adding R Packages

Edit `flake.nix` and add packages to the `rPackages` list:

```nix
rPackages = with pkgs.rPackages; [
  # existing packages...
  
  # Add your packages here
  data.table
  shiny
];
```

### Changing R Version

Override the R wrapper in `flake.nix`:

```nix
R = pkgs.rWrapper.override {
  packages = rPackages;
};
```

## Architecture

This template uses:
- **flake-parts**: Modular flake structure
- **nixpkgs**: Unstable channel for latest packages
- **perSystem**: Provides `devShells.default` and `packages`

## License

Same as the parent repository.
