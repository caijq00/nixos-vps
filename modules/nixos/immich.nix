{ ... }:

{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;
    machine-learning.enable = false;
    mediaLocation = "/var/lib/immich";
  };
}
