{ pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;

    # 自动清理未使用的镜像、容器、网络和卷
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];  # 清理所有未使用的镜像，不仅仅是悬空镜像
    };

    # Docker 守护进程配置
    daemon.settings = {
      # 日志配置，防止日志文件无限增长
      log-driver = "json-file";
      log-opts = {
        max-size = "10m";
        max-file = "3";
      };

      # Docker Hub 镜像加速
      registry-mirrors = [
        "https://docker.1ms.run"
      ];
    };
  };

  # Docker Compose V2 已经内置在 Docker 包中作为 CLI 插件
  # 使用方式: docker compose (而不是 docker-compose)
  # 如果需要兼容旧脚本，可以创建别名或安装旧版本
}
