{ hostName, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/base.nix
    ./users.nix
    ./security.nix
    ../../modules/nixos/shell.nix
    ../../modules/nixos/docker.nix
    ../../modules/nixos/incus.nix
    ../../modules/nixos/sing-box.nix
    ../../modules/nixos/emby.nix
    ../../modules/nixos/plex.nix
    ../../modules/nixos/immich.nix
  ];

  networking.hostName = hostName;

  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/vda" ];

  system.stateVersion = "24.11";
}
