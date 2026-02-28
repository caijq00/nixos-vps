{ lib, pkgs, ... }:
let
  claudeWrapper = pkgs.writeShellScriptBin "claude" ''
    if [ ! -x /var/lib/bun-global/bin/claude ]; then
      echo "claude is not installed yet. Run: nixos-rebuild switch" >&2
      exit 127
    fi
    exec /var/lib/bun-global/bin/claude "$@"
  '';

  qwenWrapper = pkgs.writeShellScriptBin "qwen" ''
    if [ -x /var/lib/bun-global/bin/qwen ]; then
      exec /var/lib/bun-global/bin/qwen "$@"
    fi
    if [ -x /var/lib/bun-global/bin/qwen-code ]; then
      exec /var/lib/bun-global/bin/qwen-code "$@"
    fi
    echo "qwen is not installed yet. Run: nixos-rebuild switch" >&2
    exit 127
  '';

  qwenCodeWrapper = pkgs.writeShellScriptBin "qwen-code" ''
    if [ -x /var/lib/bun-global/bin/qwen-code ]; then
      exec /var/lib/bun-global/bin/qwen-code "$@"
    fi
    if [ -x /var/lib/bun-global/bin/qwen ]; then
      exec /var/lib/bun-global/bin/qwen "$@"
    fi
    echo "qwen-code is not installed yet. Run: nixos-rebuild switch" >&2
    exit 127
  '';
in
{
  nixpkgs.config.allowUnfree = true;

  networking.usePredictableInterfaceNames = true;

  time.timeZone = "Asia/Shanghai";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
    ];
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      # 低内存机器建议最少保留 1 个本地构建任务
      # 当前保持 fallback=false：替代下载失败时不回退本地构建
      max-jobs = 1;
      cores = 1;
      fallback = false;
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://nix-community.cachix.org"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    optimise.automatic = true;
  };

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
  environment.localBinInPath = true;

  # Allow running foreign dynamically linked binaries (e.g. Volta-managed Node.js).
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    fzf
    tmux
    htop
    ripgrep
    fd
    bat
    eza
    duf
    bottom
    jq
    volta
    ranger
    yazi
    rustc
    cargo
    rust-analyzer
    gcc
    gnumake
    pkg-config
    cmake
    openssl
    zlib
    python3
    uv
    bun
    lsof
    strace
    iotop-c
    iftop
    sysstat
    ethtool
    nix-output-monitor
    nix-tree
    zoxide
    fastfetch
  ] ++ [
    claudeWrapper
    qwenWrapper
    qwenCodeWrapper
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."default" = {
      default = true;
      locations."/" = {
        return = "200 'nginx is running\\n'";
        extraConfig = "add_header Content-Type text/plain;";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  # Install CLI agents via bun during nixos-rebuild activation.
  system.activationScripts.bunGlobalAgents.text = ''
    set -euo pipefail

    mkdir -p /var/lib/bun-global /var/lib/bun-cache

    export BUN_INSTALL=/var/lib/bun-global
    export BUN_INSTALL_CACHE_DIR=/var/lib/bun-cache
    export PATH="$BUN_INSTALL/bin:$PATH"

    ${pkgs.bun}/bin/bun add -g @anthropic-ai/claude-code @qwen-code/qwen-code
  '';

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    priority = 100;
    memoryPercent = 40;
  };

  # Fallback disk swapfile for VPS stability.
  # Keep priority lower than zram so zram is used first.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4096; # MiB
      priority = 10;
    }
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 80;
    "vm.page-cluster" = 0;
    "fs.inotify.max_user_watches" = 524288;
    "vm.vfs_cache_pressure" = 50;
  };

  # 2G VPS: avoid using RAM-backed /tmp for builds.
  # Large build temp files on tmpfs can quickly exhaust memory and appear as "hang".
  boot.tmp.useTmpfs = false;
}
