{ ... }:

{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = false;  # Port is configured in networking.firewall (security.nix)
    machine-learning.enable = false;
    mediaLocation = "/var/lib/immich";
  };
}
