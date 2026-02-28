#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/etc/nixos/nixos-vps}"
REPO_URL="${REPO_URL:-https://github.com/caijq00/nixos-vps}"
DEFAULT_HOST_DIR="caijq"
DEFAULT_HOST_NAME="caijq"
DEFAULT_USERNAME="caijq"
CURRENT_HOST="$DEFAULT_HOST_DIR"
TARGET_HOST="$DEFAULT_HOST_DIR"
HOST_DIR_NAME="$DEFAULT_HOST_DIR"
HOST_NAME="$DEFAULT_HOST_NAME"
USERNAME="$DEFAULT_USERNAME"
TTY_AVAILABLE=0
TTY_FD=3

log() {
  printf '[nixos-vps-auto] %s\n' "$*"
}

init_tty() {
  if exec {TTY_FD}<>/dev/tty 2>/dev/null; then
    TTY_AVAILABLE=1
  else
    TTY_AVAILABLE=0
  fi
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-N}"
  local answer=""

  if [[ "$TTY_AVAILABLE" -eq 1 ]]; then
    printf '%s' "$prompt" >&${TTY_FD}
    IFS= read -r answer <&${TTY_FD} || true
  else
    log "当前会话不可交互，使用默认值: $default"
    answer="$default"
  fi

  if [[ -z "$answer" ]]; then
    answer="$default"
  fi
  printf '%s' "$answer"
}

prompt_text() {
  local prompt="$1"
  local answer=""

  if [[ "$TTY_AVAILABLE" -eq 1 ]]; then
    printf '%s' "$prompt" >&${TTY_FD}
    IFS= read -r answer <&${TTY_FD} || true
  else
    return 1
  fi

  printf '%s' "$answer"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "缺少必需命令: $1" >&2
    exit 1
  fi
}

ensure_git() {
  if command -v git >/dev/null 2>&1; then
    return 0
  fi

  log "检测到缺少 git，开始尝试临时安装"

  if command -v nix >/dev/null 2>&1; then
    if nix profile install nixpkgs#git --extra-experimental-features "nix-command flakes"; then
      hash -r
    fi
  fi

  if ! command -v git >/dev/null 2>&1 && command -v nix-env >/dev/null 2>&1; then
    if ! nix-env -iA nixpkgs.git; then
      nix-env -iA nixos.git
    fi
    hash -r
  fi

  if ! command -v git >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y git
    hash -r
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "自动安装 git 失败，请手动安装后重试。" >&2
    exit 1
  fi

  log "git 安装完成: $(git --version)"
}

read_flake_string() {
  local key="$1"
  local fallback="$2"
  local value=""

  if [[ -f "$PROJECT_DIR/flake.nix" ]]; then
    value="$(
      sed -nE "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\"([^\"]+)\";[[:space:]]*$/\\1/p" \
        "$PROJECT_DIR/flake.nix" \
        | head -n1
    )"
  fi

  if [[ -z "$value" ]]; then
    value="$fallback"
  fi
  printf '%s' "$value"
}

require_cmd sudo
ensure_git
require_cmd git
require_cmd nixos-generate-config
require_cmd nixos-rebuild
require_cmd swapon
require_cmd free

init_tty

if [[ ! -d "$PROJECT_DIR" ]]; then
  log "未找到项目目录，开始自动克隆到: $PROJECT_DIR"
  sudo mkdir -p "$(dirname "$PROJECT_DIR")"
  sudo git clone "$REPO_URL" "$PROJECT_DIR"
  log "已完成克隆: $PROJECT_DIR"
else
  log "检测到项目目录已存在，跳过克隆: $PROJECT_DIR"
fi

log "项目目录: $PROJECT_DIR"
HOST_NAME="$(read_flake_string "hostName" "$DEFAULT_HOST_NAME")"
HOST_DIR_NAME="$(read_flake_string "hostDir" "$DEFAULT_HOST_DIR")"
USERNAME="$(read_flake_string "username" "$DEFAULT_USERNAME")"
log "从 flake.nix 读取配置: hostDir='${HOST_DIR_NAME}', hostName='${HOST_NAME}', username='${USERNAME}'"

# 统一主机目录检测逻辑
mapfile -t HOST_CANDIDATES < <(find "$PROJECT_DIR/hosts" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
if [[ "${#HOST_CANDIDATES[@]}" -eq 0 ]]; then
  echo "当前 hosts/ 目录为空，请检查仓库内容。" >&2
  exit 1
elif [[ "${#HOST_CANDIDATES[@]}" -eq 1 ]]; then
  TARGET_HOST="${HOST_CANDIDATES[0]}"
  if [[ "$TARGET_HOST" != "$HOST_DIR_NAME" ]]; then
    log "警告: flake.nix 中 hostDir='${HOST_DIR_NAME}' 与实际目录 '${TARGET_HOST}' 不一致"
    log "使用实际存在的主机目录: '${TARGET_HOST}'"
  fi
elif [[ " ${HOST_CANDIDATES[*]} " == *" ${HOST_DIR_NAME} "* ]]; then
  TARGET_HOST="$HOST_DIR_NAME"
elif [[ "$TTY_AVAILABLE" -eq 1 ]]; then
  echo "检测到多个主机目录: ${HOST_CANDIDATES[*]}" >&${TTY_FD}
  if ! TARGET_HOST="$(prompt_text "请输入当前使用的主机目录名: ")"; then
    echo "无法读取主机目录名，请重试。" >&2
    exit 1
  fi
  if [[ -z "$TARGET_HOST" || ! -d "$PROJECT_DIR/hosts/$TARGET_HOST" ]]; then
    echo "主机目录无效: $TARGET_HOST" >&2
    exit 1
  fi
else
  echo "检测到多个主机目录，且 flake.nix 中 hostDir='${HOST_DIR_NAME}' 不存在，会话不可交互：" >&2
  printf '  - %s\n' "${HOST_CANDIDATES[@]}" >&2
  exit 1
fi

log "使用主机目录: '${TARGET_HOST}'，登录用户: '${USERNAME}'"

# 变量一致性检查
if [[ "$TARGET_HOST" != "$HOST_DIR_NAME" ]]; then
  log "警告: 主机目录 '${TARGET_HOST}' 与 flake.nix 中 hostDir='${HOST_DIR_NAME}' 不一致"
  log "建议: 修改 flake.nix 中的 hostDir 为 '${TARGET_HOST}'，或重命名主机目录"
fi

log "步骤 1/3: 配置 4G swapfile 到 /var/lib/swapfile"
sudo swapoff /swapfile 2>/dev/null || true
sudo swapoff /var/lib/swapfile 2>/dev/null || true
sudo chattr -i /swapfile 2>/dev/null || true
sudo chattr -i /var/lib/swapfile 2>/dev/null || true
sudo rm -f /swapfile /var/lib/swapfile
sudo mkdir -p /var/lib
if ! sudo fallocate -l 4G /var/lib/swapfile; then
  log "fallocate 失败，改用 dd 创建 swapfile"
  sudo dd if=/dev/zero of=/var/lib/swapfile bs=1M count=4096 status=progress
fi
sudo chmod 600 /var/lib/swapfile
sudo mkswap /var/lib/swapfile
sudo swapon /var/lib/swapfile
swapon --show
free -h

HOST_DIR="$PROJECT_DIR/hosts/$TARGET_HOST"
log "步骤 2/3: 为主机 '$TARGET_HOST' 生成 hardware-configuration.nix"
HW_CONFIG="$HOST_DIR/hardware-configuration.nix"
if [[ -f "$HW_CONFIG" ]]; then
  OVERWRITE="$(prompt_yes_no "检测到已存在硬件配置文件，是否覆盖？[y/N]: " "N")"
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    log "跳过硬件配置生成，使用现有文件: $HW_CONFIG"
    HW_CONFIG_GENERATED=false
  else
    log "备份现有配置到: ${HW_CONFIG}.backup"
    sudo cp "$HW_CONFIG" "${HW_CONFIG}.backup"
    sudo nixos-generate-config --show-hardware-config \
      | sudo tee "$HW_CONFIG" > /dev/null
    HW_CONFIG_GENERATED=true
  fi
else
  sudo nixos-generate-config --show-hardware-config \
    | sudo tee "$HW_CONFIG" > /dev/null
  HW_CONFIG_GENERATED=true
fi

RUN_REBUILD="$(prompt_yes_no "使用低内存参数执行 nixos-rebuild 吗？[Y/n]（默认可构建模式）: " "Y")"
USE_OFFICIAL_CACHE="$(prompt_yes_no "是否强制只使用官方缓存(cache.nixos.org)？[y/N]: " "N")"

REBUILD_ARGS=()
FLAKE_REF="path:${PROJECT_DIR}#${HOST_NAME}"

if [[ "$RUN_REBUILD" =~ ^[Yy]$ ]]; then
  log "步骤 3/3: 使用低内存参数执行 rebuild"
  REBUILD_ARGS=(
    switch --flake "$FLAKE_REF" -L
    --option max-jobs 1
    --option cores 1
    --option fallback false
  )
else
  log "步骤 3/3: 执行标准 rebuild（含 -L 日志，max-jobs=1）"
  REBUILD_ARGS=(
    switch --flake "$FLAKE_REF" -L
    --option max-jobs 1
    --option cores 1
  )
fi

# 如果选择强制使用官方缓存,追加 substituters 参数
if [[ "$USE_OFFICIAL_CACHE" =~ ^[Yy]$ ]]; then
  log "已启用: 强制只使用官方缓存(跳过国内镜像)"
  REBUILD_ARGS+=(--option substituters https://cache.nixos.org)
fi

set +e
if [[ "$TTY_AVAILABLE" -eq 1 ]]; then
  sudo nixos-rebuild --verbose "${REBUILD_ARGS[@]}" <&${TTY_FD}
else
  sudo nixos-rebuild --verbose "${REBUILD_ARGS[@]}"
fi
REBUILD_RC=$?
set -e

if [[ "$REBUILD_RC" -eq 0 ]]; then
  log "rebuild 成功（退出码: $REBUILD_RC）"
else
  log "rebuild 失败（退出码: $REBUILD_RC）"
  if [[ "${HW_CONFIG_GENERATED:-false}" == "true" && -f "${HW_CONFIG}.backup" ]]; then
    log "提示: 如需恢复硬件配置，运行: sudo cp ${HW_CONFIG}.backup ${HW_CONFIG}"
  fi
  exit "$REBUILD_RC"
fi

log "完成。请核对以下信息："
echo "  - SSH 端口: 9527"
echo "  - 登录用户: $USERNAME"
echo "  - 初始密码: change-me（登录后到 hosts/${TARGET_HOST}/users.nix 修改 initialPassword）"
echo "  - 主机配置: flake.nix 中 hostName='${HOST_NAME}'"
if [[ "$TARGET_HOST" != "$HOST_DIR_NAME" ]]; then
  echo "  - 警告: 实际使用主机目录 '${TARGET_HOST}' 与 flake.nix 中 hostDir='${HOST_DIR_NAME}' 不一致"
fi
echo "  - 建议操作: rebuild 完成后重启一次系统（sudo reboot）"
echo "  - 重启前请先验证 SSH 端口和用户策略，避免锁在外面"

if [[ "$TTY_AVAILABLE" -eq 1 ]]; then
  exec {TTY_FD}>&-
fi
