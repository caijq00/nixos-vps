{ pkgs, ... }:

let
  embyPkg = pkgs.callPackage ../../pkgs/emby-server.nix { };
  embyRoot = "${embyPkg}/opt/emby-server";
  embyLibPath = "${embyRoot}/lib:${embyRoot}/extra/lib";
in
{
  users.groups.emby = { };
  users.users.emby = {
    isSystemUser = true;
    group = "emby";
    home = "/var/lib/emby";
    createHome = true;
  };

  # Emby launcher expects /opt/emby-server. Provide a stable symlink to the Nix store path.
  systemd.tmpfiles.rules = [
    "L+ /opt/emby-server - - - - ${embyRoot}"
  ];

  systemd.services.emby = {
    description = "Emby Server";
    after = [ "network-online.target" "systemd-tmpfiles-setup.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "emby";
      Group = "emby";
      WorkingDirectory = "/var/lib/emby";
      ExecStart = "${embyRoot}/bin/emby-server";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "EMBY_DATA=/var/lib/emby"
        "LD_LIBRARY_PATH=${embyLibPath}"
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 8096 8920 ];

  environment.systemPackages = [ embyPkg ];
}
