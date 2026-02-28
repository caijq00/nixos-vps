{ pkgs, username, ... }:

let
  tunaImages = "https://mirrors.tuna.tsinghua.edu.cn/lxc-images/";
in
{
  virtualisation.incus = {
    enable = true;

    # Declarative base init for bridge network + default storage/profile.
    preseed = {
      networks = [
        {
          name = "incusbr0";
          type = "bridge";
          config = {
            "ipv4.address" = "auto";
            "ipv4.nat" = "true";
            "ipv6.address" = "auto";
            "ipv6.nat" = "true";
          };
        }
      ];

      storage_pools = [
        {
          name = "default";
          driver = "dir";
          config = {
            source = "/var/lib/incus/storage-pools/default";
          };
        }
      ];

      profiles = [
        {
          name = "default";
          devices = {
            eth0 = {
              name = "eth0";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              type = "disk";
            };
          };
        }
      ];
    };
  };

  networking.nftables.enable = true;
  networking.firewall.trustedInterfaces = [ "incusbr0" ];

  users.users.${username}.extraGroups = [ "incus-admin" ];

  # Keep Incus image remotes pinned to TUNA mirror after rebuild/reboot.
  systemd.services.incus-configure-images-remote = {
    description = "Configure Incus image remotes to TUNA mirror";
    after = [ "incus.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [ pkgs.incus ];

    script = ''
      set -euo pipefail

      # Optional named mirror remote for manual usage.
      incus remote add mirror-images "${tunaImages}" --protocol=simplestreams --public 2>/dev/null || true
      incus remote set-url mirror-images "${tunaImages}" 2>/dev/null || true

      # Override default "images" remote so existing commands keep working.
      if ! incus remote set-url images "${tunaImages}" 2>/dev/null; then
        incus remote remove images 2>/dev/null || true
        incus remote add images "${tunaImages}" --protocol=simplestreams --public
      fi
    '';
  };
}
