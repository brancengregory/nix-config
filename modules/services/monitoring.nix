{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.monitoring;
in {
  options.services.monitoring = {
    enable = mkEnableOption "system monitoring stack (Prometheus/Grafana)";

    exporters = {
      enable = mkEnableOption "Prometheus node exporters (lightweight metrics collection)";
      
      port = mkOption {
        type = types.port;
        default = 9100;
        description = "Port for node exporter";
      };
      
      collectors = mkOption {
        type = types.listOf types.str;
        default = [ "systemd" ];
        description = "Enabled metric collectors";
      };
    };

    server = {
      enable = mkEnableOption "Prometheus server (HEAVY - only enable on monitoring host)";
      
      prometheusPort = mkOption {
        type = types.port;
        default = 9090;
        description = "Port for Prometheus server";
      };
      
      grafanaPort = mkOption {
        type = types.port;
        default = 3000;
        description = "Port for Grafana dashboard";
      };
      
      grafanaBind = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address to bind Grafana (use 0.0.0.0 for external access)";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Exporters (lightweight - can run on all nodes)
    (mkIf cfg.exporters.enable {
      services.prometheus.exporters.node = {
        enable = true;
        port = cfg.exporters.port;
        enabledCollectors = cfg.exporters.collectors;
      };
    })

    # Server stack (heavyweight - only on designated monitoring host)
    (mkIf cfg.server.enable {
      services.prometheus = {
        enable = true;
        port = cfg.server.prometheusPort;
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [
              {
                targets = [ "localhost:${toString cfg.exporters.port}" ];
              }
            ];
          }
        ];
      };

      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_port = cfg.server.grafanaPort;
            http_addr = cfg.server.grafanaBind;
          };
        };
      };
    })
  ]);
}
