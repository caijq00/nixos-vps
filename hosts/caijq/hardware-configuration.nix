# Placeholder for VPS hardware config.
# Replace this file on the target VPS with:
#   sudo nixos-generate-config --show-hardware-config > /etc/nixos/nixos-vps/hosts/caijq/hardware-configuration.nix
{ ... }:
{
  assertions = [
    {
      assertion = false;
      message = ''
        hosts/caijq/hardware-configuration.nix is still a placeholder.
        Generate and replace it before deploy:
          sudo nixos-generate-config --show-hardware-config > /etc/nixos/nixos-vps/hosts/caijq/hardware-configuration.nix
      '';
    }
  ];
}
