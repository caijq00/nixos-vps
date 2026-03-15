{ hostName, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ./users.nix
    ./security.nix
    ../../modules/nixos/shell.nix
    ../../modules/nixos/docker.nix
    ../../modules/compose/dockge.nix
    # ../../modules/nixos/incus.nix
    ../../modules/nixos/sing-box.nix
    # ../../modules/nixos/emby.nix
    ../../modules/nixos/plex.nix
    ../../modules/nixos/immich.nix
  ];

  networking.hostName = hostName;
  # Dockge is managed declaratively via the NixOS module above.
  # Do not manage Dockge through compose/dockge/docker-compose.yml.
  my.services.dockge.openFirewall = true;

  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/vda" ];

  system.stateVersion = "24.11";
}
