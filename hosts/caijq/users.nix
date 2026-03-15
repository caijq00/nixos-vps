{ pkgs, username, ... }:

{
  users = {
    defaultUserShell = pkgs.zsh;
    users = {
      root = {
        shell = pkgs.zsh;
        home = "/root";
      };
      ${username} = {
        isNormalUser = true;
        extraGroups = [ "wheel" "docker" ];
        shell = pkgs.zsh;
        home = "/home/${username}";
        initialPassword = "change-me";
      };
    };
  };
}
