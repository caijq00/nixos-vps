{ pkgs, username, hostName, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = username;
    userEmail = "${username}@example.com";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initExtra = ''
      if [[ $- == *i* ]] && command -v fastfetch >/dev/null 2>&1; then
        fastfetch
      fi

      export VOLTA_HOME="$HOME/.volta"
      export PATH="$VOLTA_HOME/bin:$PATH"
      export PATH="$HOME/.cargo/bin:$PATH"

      # Use Up/Down to search history by current command prefix and keep cursor at line end.
      autoload -Uz history-search-end
      zle -N history-beginning-search-backward-end history-search-end
      zle -N history-beginning-search-forward-end history-search-end
      bindkey "^[[A" history-beginning-search-backward-end
      bindkey "^[[B" history-beginning-search-forward-end
      bindkey "^[OA" history-beginning-search-backward-end
      bindkey "^[OB" history-beginning-search-forward-end

      # Make Right Arrow accept autosuggestion.
      bindkey "^[[C" autosuggest-accept
      bindkey "^[OC" autosuggest-accept
    '';
    history = {
      size = 10000;
      ignoreAllDups = true;
    };
    plugins = [
      {
        name = "sudo";
        src = "${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/sudo";
      }
    ];
    shellAliases = {
      c = "clear";
      cc = "claude";
      cx = "codex";
      ra = "sudo ranger";
      ll = "eza -al --icons";
      la = "eza -a --icons";
      gs = "git status";
      cat = "bat";
      vi = "nvim";
      vim = "nvim";
      up = "sudo nixos-rebuild switch --flake .#${hostName}";
      chk = "nix flake check";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd" "j" ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = false;
  };

  home.file.".cargo/config.toml".text = ''
    [source.crates-io]
    replace-with = "tuna"

    [source.tuna]
    registry = "sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"
  '';

  home.file.".npmrc".text = ''
    registry=https://registry.npmmirror.com/
  '';

  home.file.".config/uv/uv.toml".text = ''
    [[index]]
    url = "https://pypi.tuna.tsinghua.edu.cn/simple"
    default = true
  '';

  home.packages = with pkgs; [
    unzip
    zip
    tree
  ];
}
