{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.sing-box ];

  # Minimal bootstrapping config so service starts even before custom config is provided.
  environment.etc."sing-box/config.json".text = ''
    {
      "log": {
        "level": "info"
      },
      "inbounds": [],
      "outbounds": [
        {
          "type": "direct",
          "tag": "direct"
        },
        {
          "type": "block",
          "tag": "block"
        }
      ],
      "route": {
        "rules": []
      }
    }
  '';

  systemd.tmpfiles.rules = [
    "d /var/lib/sing-box 0750 root root -"
  ];

  systemd.services.sing-box = {
    description = "sing-box service";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.sing-box}/bin/sing-box run -D /var/lib/sing-box -c /etc/sing-box/config.json";
      Restart = "on-failure";
      RestartSec = "3s";
      User = "root";
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
      NoNewPrivileges = true;
      LimitNOFILE = 1048576;
    };
  };
}
