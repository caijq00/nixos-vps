{ pkgs, ... }:

{
  programs.zsh.enable = true;

  environment.shells = [ pkgs.zsh ];

  programs.tmux = {
    enable = true;
    clock24 = true;
    terminal = "screen-256color";
  };
}
