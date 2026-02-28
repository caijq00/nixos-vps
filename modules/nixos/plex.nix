{ ... }:

{
  services.plex = {
    enable = true;
    openFirewall = false;
  };

  networking.firewall.allowedTCPPorts = [ 32456 ];

  networking.nftables.enable = true;

  # Add a dedicated NAT table for Plex remap without replacing global nftables rules.
  networking.nftables.tables."plex-nat" = {
    family = "ip";
    content = ''
      chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        tcp dport 32456 dnat to 127.0.0.1:32400
      }
      chain output {
        type nat hook output priority -100; policy accept;
        tcp dport 32456 dnat to 127.0.0.1:32400
      }
    '';
  };
}
