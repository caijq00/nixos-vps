{ lib, config, ... }:

let
  cfg = config.my.services.dockge;
in
{
  options.my.services.dockge = {
    enable = lib.mkEnableOption "Dockge" // {
      default = true;
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5001;
      description = "Host port Dockge listens on (used for firewall only).";
    };

    stacksDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos/nixos-vps/compose";
      description = "Directory containing docker compose stacks.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos/nixos-vps/compose/dockge";
      description = "Dockge data directory.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the Dockge port.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend = "docker";

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    virtualisation.oci-containers.containers.dockge = {
      image = "louislam/dockge:latest";
      autoStart = true;
      ports = [ "${toString cfg.port}:5001" ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "${cfg.stacksDir}:/opt/stacks"
        "${cfg.dataDir}:/app/data"
      ];
      environment = {
        DOCKGE_STACKS_DIR = "/opt/stacks";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
