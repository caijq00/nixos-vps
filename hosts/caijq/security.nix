{ lib, username, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      AllowAgentForwarding = false;
      AllowUsers = [ username ];
      Port = 9527;
    };
  };

  # services.fail2ban.enable = true;

  # Use traditional NixOS firewall (iptables-nft backend).
  networking.firewall = lib.mkForce {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [ 80 443 9527 2283 5001 32400 32456 ];
    trustedInterfaces = [ "docker0" ];
    # Keep Plex external port 32456 mapped to local 32400.
    extraCommands = ''
      iptables -t nat -A PREROUTING -p tcp --dport 32456 -j DNAT --to-destination 127.0.0.1:32400
      iptables -t nat -A OUTPUT -p tcp --dport 32456 -j DNAT --to-destination 127.0.0.1:32400
    '';
    extraStopCommands = ''
      iptables -t nat -D PREROUTING -p tcp --dport 32456 -j DNAT --to-destination 127.0.0.1:32400 || true
      iptables -t nat -D OUTPUT -p tcp --dport 32456 -j DNAT --to-destination 127.0.0.1:32400 || true
    '';
  };

  # Ensure nftables native rules are disabled; firewall uses iptables-nft backend.
  networking.nftables.enable = lib.mkForce false;

  # sudo 配置: wheel 组默认需要密码,但为主用户配置免密 sudo
  security.sudo = {
    wheelNeedsPassword = true;
    extraRules = [
      {
        users = [ username ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
