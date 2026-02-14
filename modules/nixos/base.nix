{ lib, pkgs, ... }:

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
      # 完全禁止本地编译(max-jobs = 0)
      # 警告: 这会禁止任何本地构建,包括系统配置组装
      # 如果缓存未命中会直接失败,确保所有包都有二进制缓存
      # 若 rebuild 报错 "Unable to start any build",改为 max-jobs = 1
      max-jobs = 0;
      cores = 1;
      fallback = false;
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
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
    RUSTUP_DIST_SERVER = "https://mirrors.tuna.tsinghua.edu.cn/rustup";
    RUSTUP_UPDATE_ROOT = "https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup";
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
    rustup
    rust-analyzer
    python3
    uv
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
  ];

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
