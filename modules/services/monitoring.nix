{
  config,
  pkgs,
  ...
}: {
  # --- Prometheus (Metrics Database) ---
  services.prometheus = {
    enable = true;
    port = 9090;

    # Exporters (Data Collectors)
    exporters = {
      node = {
        enable = true;
        enabledCollectors = ["systemd"];
        port = 9100;
      };
    };

    # Scrape Configurations
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["localhost:9100"];
          }
        ];
      }
    ];
  };

  # --- Grafana (Visualization Dashboard) ---
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0"; # Listen on all interfaces
      };
    };
  };

  # Firewall managed by host (VPN-only)
}
