#!/bin/bash
set -e

# 定义颜色以提高可读性
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GRAY='\033[0;90m'
NC='\033[0m' # 无颜色

# 日志函数
log_debug() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${BLUE}[DEBUG]${NC} ${GRAY}$1"; }
log_info() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${GREEN}[ INFO]${NC} $1"; }
log_warn() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${YELLOW}[ WARN]${NC} $1"; }
log_error() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${RED}[ERROR]${NC} $1"; exit 1; }

# 默认配置变量
COMPOSE_FILE="compose.yaml"
ENV_FILE=".env"
IMAGE_MODE="pull"

ZERO_DOCKER_REGISTRY=""
ZERO_REGISTRY_NAMESPACE=""
ZERO_NAMESPACE="zero"
ZERO_IMAGE_TAG="tiny-latest"

# 包管理器
PACKAGE_MANAGER=""

# 本机 IP
HOST_IP=$(hostname -I | awk '{print $1}')

# NFS 地址
ZERO_NFS_HOST="${HOST_IP}"

# 显示帮助信息
show_help() {
  echo -e "${BLUE}Docker 部署脚本${NC}"
  echo "用法: $(basename "$0") [选项]"
  echo ""
  echo "选项:"
  echo "  -h, --help                    # 显示帮助信息"
  echo "  -m, --mode [pull|build]  # 镜像模式：pull 拉取仓库镜像，build 本地构建镜像 (默认: pull)"
  echo ""
  echo "示例:"
  echo "  $(basename "$0")              # 一键部署所有服务"
  echo "  $(basename "$0") -m build     # 本地构建镜像并且一键部署所有服务"
}

# 参数处理
parse_args() {
  WORK_DIR="$(pwd)"

  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      -m|--mode)
        if [ -z "$2" ]; then
          log_error "参数 -m | --mode 需要一个值"
        fi
        case "$2" in
          pull|build|skip)
            IMAGE_MODE="$2"
            shift 2
            ;;
          *)
            log_error "参数 -m | --mode 只能是 pull 或 build"
            ;;
        esac
        ;;
      *)
        log_error "未知参数: $1 \n 请使用 -h 或 --help 查看帮助信息"
        ;;
    esac
  done

}

# 检查 root 权限
check_root() {
  # 检查是否为 root 用户（安装软件通常需要 root 权限）
  if [ "$(id -u)" -ne 0 ]; then
    log_error "请以 root 用户或使用 sudo 权限运行此脚本！（sudo $(basename "$0")）"
  fi
}

# 检查操作系统
check_os() {
  log_info "检查操作系统..."
  local uname_s
  uname_s="$(uname -s 2>/dev/null || true)"
  if [ "$uname_s" != "Linux" ]; then
    log_error "此脚本仅支持 Linux 操作系统。"
  fi

  log_info "检查操作系统版本..."
  if [ -r /etc/os-release ]; then
    . /etc/os-release
  else
    log_error "无法检测操作系统（未找到 /etc/os-release 文件）"
  fi

  # 规范化与展示
  local id_lc id_like_lc ver
  id_lc="$(printf '%s' "${ID:-}" | tr '[:upper:]' '[:lower:]')"
  id_like_lc="$(printf '%s' "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
  ver="${VERSION_ID:-unknown}"

  OS="${NAME:-$id_lc}"
  VERSION="$ver"
  log_info "检测到操作系统：${OS} ${VERSION}"

  # 选择包管理器
  local pm=""
  case ",$id_lc,$id_like_lc," in
    *,debian,*|*,ubuntu,*|*,linuxmint,*|*,kali,*|*,raspbian,*|*,deepin,*|*,uos,*)
      pm="apt"
      ;;
    *,rhel,*|*,centos,*|*,rocky,*|*,almalinux,*|*,ol,*|*,oracle,*|*,redhat,*)
      if command -v dnf >/dev/null 2>&1; then pm="dnf"; else pm="yum"; fi
      ;;
    *,fedora,*)
      pm="dnf"
      ;;
    *,sles,*|*,suse,*|*,opensuse,*)
      pm="zypper"
      ;;
    *,arch,*|*,manjaro,*|*,endeavouros,*)
      pm="pacman"
      ;;
    *,alpine,*)
      pm="apk"
      ;;
    *,amzn,*|*,amazon,*)
      if command -v dnf >/dev/null 2>&1; then pm="dnf"; else pm="yum"; fi
      ;;
    *,openeuler,*|*,euleros,*)
      if command -v dnf >/dev/null 2>&1; then pm="dnf"; else pm="yum"; fi
      ;;
    *)
      # 回退：按常见管理器检测
      for cand in apt dnf yum zypper pacman apk; do
        if command -v "$cand" >/dev/null 2>&1; then pm="$cand"; break; fi
      done
      ;;
  esac

  [ -z "$pm" ] && log_error "不支持的操作系统或未找到包管理器：ID=${id_lc} ID_LIKE=${id_like_lc}"
  if ! command -v "$pm" >/dev/null 2>&1; then
    log_error "${pm} 包管理器不可用，请检查系统配置！"
  fi

  PACKAGE_MANAGER="$pm"
  log_info "使用包管理器：${PACKAGE_MANAGER}"
}

# 检查 Docker 是否安装
check_docker() {
  log_info "检查 Docker 环境..."
  if ! command -v docker > /dev/null 2>&1; then
    log_warn "未找到 Docker 命令。请确保 Docker 已安装并添加到 PATH 中。
    可以使用以下命令安装 Docker：
    curl -fsSL https://get.docker.com | sudo sh
    参考 Docker 官方文档： https://docs.docker.com/engine/install/"
    # 交互式安装 Docker
    read -r -p "是否要安装 Docker？(Y/N，默认Y): " install_docker
    if [[ -z "$install_docker" || "$install_docker" =~ ^[Yy]$ ]]; then
      log_info "开始安装 Docker..."
      if command -v curl > /dev/null 2>&1; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
      else
        log_error "未找到 curl 命令，无法自动安装 Docker。请手动安装 Docker。
        参考 Docker 官方文档： https://docs.docker.com/engine/install/"
      fi
    else
      log_error "Docker 未安装，部署终止。请安装 Docker 后重试。
      参考 Docker 官方文档： https://docs.docker.com/engine/install/"
    fi
  fi

  log_debug "检查 Docker Swarm 模式..."
  if ! docker info | grep 'Swarm: active'; then
    log_info "Docker Swarm 未激活，正在初始化..."
    docker swarm init || log_error "初始化 Docker Swarm 失败！"
    log_debug "Docker Swarm 初始化成功"
  else
    log_debug "Docker Swarm 已激活"
  fi

  log_debug "Docker 环境检查通过"
}

# 提取 ${ENV_FILE} 文件中的变量
parse_env() {
  # 检查是否存在 ${ENV_FILE} 文件
  local env_file="docker/$ENV_FILE"

  # 设置默认值
  ZERO_DIR="/zero"

  # 如果 ${ENV_FILE} 文件存在，则读取变量
  if [ -f "$env_file" ]; then
    log_info "从 ${env_file} 文件中提取环境变量..."

    while IFS= read -r line || [ -n "$line" ]; do
      # 跳过空行注释
      [ -z "$line" ] || [[ $line == \#* ]] && continue

      # 提取键值对
      if [[ "$line" =~ ^([A-Za-z0-9_]+)=(.*)$ ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"

        # 移除引号
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"

        # 设置全局变量
        declare -g "$key"="$value"
        log_debug "设置变量: $key=$value"
      fi
    done < "$env_file"

    log_debug "环境变量提取完成"
  else
    log_warn "文件 $env_file 不存在，使用默认值"
  fi

  # 输出使用的变量值
  log_info "变量值: ZERO_DIR=$ZERO_DIR"

  # 询问用户是否使用这些变量
  read -r -p "是否使用这些变量？(Y/N，默认Y): " use_vars
  if [[ -z "$use_vars" || "$use_vars" =~ ^[Yy]$ ]]; then
    log_info "使用变量: ZERO_DIR=${ZERO_DIR}"
  else
    log_error "用户选择不使用变量，部署终止。请调整 ${env_file} 文件中的变量后重试。"
  fi

}

# 设置密码函数
set_password() {
  # 优先从 ${ZERO_DIR}/conf/mysql/password.txt 或 docker/${ENV_FILE} 读取已存在的 MYSQL_PASSWORD
  if [ -z "$MYSQL_PASSWORD" ]; then
    if [ -f "${ZERO_DIR}/conf/mysql/password.txt" ]; then
      MYSQL_PASSWORD=$(cat "${ZERO_DIR}/conf/mysql/password.txt")
    elif [ -f "docker/${ENV_FILE}" ]; then
      MYSQL_PASSWORD=$(grep -E '^MYSQL_PASSWORD=' "docker/${ENV_FILE}" | cut -d'=' -f2-)
    fi
  fi

  # 设置 MySQL 密码
  if [ -z "$MYSQL_PASSWORD" ]; then
    log_info "随机生成 MySQL 密码，或者手动输入密码..."
    read -r -p "是否随机生成 MySQL 密码？(Y/N，默认Y): " generate_password
    if [[ -z "$generate_password" || "$generate_password" =~ ^[Yy]$ ]]; then
      MYSQL_PASSWORD=$(tr -dc '0-9A-Za-z_-' < /dev/urandom | head -c 8; echo)
      log_info "随机生成 MySQL 密码: ${MYSQL_PASSWORD}"
    else
      # 循环请求用户输入密码，直到满足要求
      while true; do
        read -r -p "请输入 MySQL 密码 (4-20位): " input_password
        if [ -z "$input_password" ]; then
          log_warn "MySQL 密码不能为空！请重新输入..."
        elif [ ${#input_password} -lt 4 ] || [ ${#input_password} -gt 20 ]; then
          log_warn "MySQL 密码长度必须在4-20位之间！请重新输入..."
        else
          MYSQL_PASSWORD="$input_password"
          log_info "使用用户输入的 MySQL 密码: ${MYSQL_PASSWORD}"
          break
        fi
      done
    fi
  else
    log_info "检测到已存在的 MySQL 密码: ${MYSQL_PASSWORD}"
  fi


  # 优先从 ${ZERO_DIR}/conf/redis/password.txt 或 docker/${ENV_FILE} 读取已存在的 REDIS_PASSWORD
  if [ -z "$REDIS_PASSWORD" ]; then
    if [ -f "${ZERO_DIR}/conf/redis/password.txt" ]; then
      REDIS_PASSWORD=$(cat "${ZERO_DIR}/conf/redis/password.txt")
    elif [ -f "docker/${ENV_FILE}" ]; then
      REDIS_PASSWORD=$(grep -E '^REDIS_PASSWORD=' "docker/${ENV_FILE}" | cut -d'=' -f2-)
    fi
  fi

  # 设置 Redis 密码
  if [ -z "$REDIS_PASSWORD" ]; then
    log_info "随机生成 Redis 密码，或者手动输入密码..."
    read -r -p "是否随机生成 Redis 密码？(Y/N，默认Y): " generate_password
    if [[ -z "$generate_password" || "$generate_password" =~ ^[Yy]$ ]]; then
      REDIS_PASSWORD=$(tr -dc '0-9A-Za-z_-' < /dev/urandom | head -c 8; echo)
      log_info "随机生成 Redis 密码: ${REDIS_PASSWORD}"
    else
      # 循环请求用户输入密码，直到满足要求
      while true; do
        read -r -p "请输入 Redis 密码 (4-20位): " input_password
        if [ -z "$input_password" ]; then
          log_warn "Redis 密码不能为空！请重新输入..."
        elif [ ${#input_password} -lt 4 ] || [ ${#input_password} -gt 20 ]; then
          log_warn "Redis 密码长度必须在4-20位之间！请重新输入..."
        else
          REDIS_PASSWORD="$input_password"
          log_info "使用用户输入的 Redis 密码: ${REDIS_PASSWORD}"
          break
        fi
      done
    fi
  else
    log_info "检测到已存在的 Redis 密码: ${REDIS_PASSWORD}"
  fi

}

# 创建目录函数
create_dir() {
  log_info "准备创建目录并赋予权限..."
  local dirs=("${ZERO_DIR}/conf" "${ZERO_DIR}/data" "${ZERO_DIR}/logs")
  local names=("conf" "data" "logs")

  for i in "${!dirs[@]}"; do
    if [ ! -d "${dirs[$i]}" ]; then
      log_info "创建 ${names[$i]} 目录: ${dirs[$i]}..."
      mkdir -p "${dirs[$i]}" || log_error "创建 ${names[$i]} 目录失败！"
      chmod 755 "${dirs[$i]}" || log_warn "设置 ${names[$i]} 目录权限失败！"
      log_debug "${names[$i]} 目录创建成功"
    else
      log_debug "${names[$i]} 目录已存在: ${dirs[$i]}"
    fi
  done

  # 复制 ${ENV_FILE} 文件到 APP_DIR
  if [ ! -f "${ZERO_DIR}/conf/${ENV_FILE}" ]; then
    log_info "复制 ${ENV_FILE} 文件到 ${ZERO_DIR}/conf ..."
    cp "${WORK_DIR}/docker/${ENV_FILE}" "${ZERO_DIR}/conf/" || log_error "复制 ${ENV_FILE} 文件失败！"
    chmod 644 "${ZERO_DIR}/conf/${ENV_FILE}" || log_warn "设置 ${ENV_FILE} 文件权限失败！"
    log_debug "${ENV_FILE} 文件复制成功"
  else
    log_debug "${ENV_FILE} 文件已存在: ${ZERO_DIR}/conf/${ENV_FILE}"
  fi

  # 替换环境变量
  replace_envs

  # 复制 update.sh 文件到 APP_DIR
  if [ ! -f "${ZERO_DIR}/conf/update.sh" ]; then
    log_info "复制 update.sh 文件到 ${ZERO_DIR}/conf ..."
    cp "${WORK_DIR}/docker/update.sh" "${ZERO_DIR}/conf/" || log_error "复制 update.sh 文件失败！"
    chmod +x "${ZERO_DIR}/conf/update.sh" || log_warn "设置 update.sh 文件权限失败！"
    log_debug "update.sh 文件复制成功"
  else
    log_debug "update.sh 文件已存在: ${ZERO_DIR}/conf/update.sh"
  fi
}

# 判断包是否已安装
is_pkg_installed() {
  local pkg="$1"
  case "$PACKAGE_MANAGER" in
    apt)
      dpkg -s "$pkg" >/dev/null 2>&1
      ;;
    dnf|yum|zypper)
      rpm -q "$pkg" >/dev/null 2>&1
      ;;
    pacman)
      pacman -Qi "$pkg" >/dev/null 2>&1
      ;;
    apk)
      apk info -e "$pkg" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

# 安装包
install_pkg() {
  local pkg="$1"
  log_info "使用 ${PACKAGE_MANAGER} 安装包: ${pkg} ..."
  case "$PACKAGE_MANAGER" in
    apt)
      apt-get update -y || log_warn "apt-get update 失败，继续尝试安装..."
      apt-get install -y "$pkg" || return 1
      ;;
    dnf)
      dnf install -y "$pkg" || return 1
      ;;
    yum)
      yum install -y "$pkg" || return 1
      ;;
    zypper)
      zypper --non-interactive install -y "$pkg" || return 1
      ;;
    pacman)
      pacman -Sy --noconfirm "$pkg" || return 1
      ;;
    apk)
      apk add --no-cache "$pkg" || return 1
      ;;
    *)
      return 1
      ;;
  esac
  return 0
}

# 创建 NFS
create_nfs() {
  log_info "检查 NFS 服务..."

  local svc_candidates=(nfs-server nfs-kernel-server nfs)
  local pkg exports_file opts found_svc s backup_ts esc_dir existing new_line

  # 选择包名
  if [ "$PACKAGE_MANAGER" = "apt" ]; then
    pkg="nfs-kernel-server"
  else
    pkg="nfs-utils"
  fi

  # 确保已安装
  if ! is_pkg_installed "$pkg"; then
    log_info "安装 ${pkg} ..."
    install_pkg "$pkg" || log_error "安装包 ${pkg} 失败，请手动检查系统包管理器或网络"
  else
    log_debug "包 ${pkg} 已安装"
  fi

  # 启动服务（systemd 优先）
  found_svc=""
  if command -v systemctl >/dev/null 2>&1; then
    for s in "${svc_candidates[@]}"; do
      if systemctl list-unit-files --type=service | grep -Eq "^${s}\.service"; then
        found_svc="$s"
        break
      fi
    done
    if [ -n "$found_svc" ]; then
      if systemctl is-active --quiet "$found_svc"; then
        log_debug "NFS 服务 ${found_svc} 已在运行"
      else
        log_info "启动 NFS 服务 ${found_svc} ..."
        systemctl enable --now "$found_svc" >/dev/null 2>&1 \
          && log_info "NFS 服务 ${found_svc} 启动成功" \
          || log_warn "NFS 服务 ${found_svc} 启动失败，请稍后检查"
      fi
    else
      log_warn "未发现已知的 NFS 服务单元（nfs-server/nfs-kernel-server/nfs），继续处理导出"
    fi
  else
    # 兼容非 systemd 系统
    if command -v service >/dev/null 2>&1; then
      for s in "${svc_candidates[@]}"; do
        if service "$s" start >/dev/null 2>&1; then
          log_info "通过 service 启动 NFS 服务 ${s} 成功"
          found_svc="$s"
          break
        fi
      done
    fi
    [ -z "$found_svc" ] && log_warn "无法通过传统方式确认或启动 NFS 服务，继续处理导出"
  fi

  # 确保导出目录存在
  [ -d "$ZERO_DIR" ] || { mkdir -p "$ZERO_DIR" || log_error "创建目录 ${ZERO_DIR} 失败"; chmod 755 "$ZERO_DIR" || true; }

  # 配置 /etc/exports（幂等）
  exports_file="/etc/exports"
  opts="rw,sync,no_subtree_check,no_root_squash"
  backup_ts=$(date +%s)
  [ -f "$exports_file" ] && cp "$exports_file" "${exports_file}.bak.${backup_ts}" 2>/dev/null || true

  # 转义路径用于正则
  esc_dir=$(printf '%s' "$ZERO_DIR" | sed -e 's/[].[^$\\*/]/\\&/g')
  existing=$(grep -E "^[[:space:]]*${esc_dir}\b" "$exports_file" 2>/dev/null || true)
  new_line="${ZERO_DIR} ${HOST_IP}(${opts}) 127.0.0.1(${opts}) ::1(${opts})"

  if [ -n "$existing" ]; then
    if printf '%s\n' "$existing" | grep -Eq "(\b${HOST_IP}\b|127\.0\.0\.1|\blocalhost\b|::1)"; then
      log_debug "已存在对 ${ZERO_DIR} 的导出且包含本机访问，跳过追加"
    else
      if ! grep -Fxq "$new_line" "$exports_file" 2>/dev/null; then
        echo "$new_line" >> "$exports_file" || log_error "写入 ${exports_file} 失败"
        log_info "已为 ${ZERO_DIR} 追加允许本机访问的导出"
      fi
    fi
  else
    if ! grep -Fxq "$new_line" "$exports_file" 2>/dev/null; then
      echo "$new_line" >> "$exports_file" || log_error "写入 ${exports_file} 失败"
      log_info "已为 ${ZERO_DIR} 添加导出"
    fi
  fi

  # 刷新导出（无需重启服务）
  if command -v exportfs >/dev/null 2>&1; then
    exportfs -r >/dev/null 2>&1 || exportfs -a >/dev/null 2>&1 || log_error "exportfs 刷新导出失败"
    log_info "NFS 导出已刷新生效"
  else
    log_error "未找到 exportfs 命令，请确认 NFS 工具已正确安装"
  fi

}

# 替换环境变量
replace_envs() {
  # 将目录中的 ${ENV_FILE} 文件中的变量替换为实际值 APP_DIR=${ZERO_DIR}/conf DATA_DIR=${ZERO_DIR}/data LOGS_DIR=${ZERO_DIR}/logs
  log_debug "替换 ${ENV_FILE} 文件中的变量..."
  sed -i "s|APP_DIR=.*|APP_DIR=${ZERO_DIR}/conf|" "${ZERO_DIR}/conf/${ENV_FILE}" || log_error "替换 APP_DIR 变量失败！"
  sed -i "s|DATA_DIR=.*|DATA_DIR=${ZERO_DIR}/data|" "${ZERO_DIR}/conf/${ENV_FILE}" || log_error "替换 DATA_DIR 变量失败！"
  sed -i "s|LOGS_DIR=.*|LOGS_DIR=${ZERO_DIR}/logs|" "${ZERO_DIR}/conf/${ENV_FILE}" || log_error "替换 LOGS_DIR 变量失败！"
  sed -i "s|CODE_DIR=.*|CODE_DIR=${WORK_DIR}|" "${ZERO_DIR}/conf/${ENV_FILE}" || log_error "替换 CODE_DIR 变量失败！"
  sed -i "s|ZERO_DOCKER_REGISTRY=.*|ZERO_DOCKER_REGISTRY=${ZERO_DOCKER_REGISTRY}|" "${ZERO_DIR}/conf/${ENV_FILE}" || log_error "替换 ZERO_DOCKER_REGISTRY 变量失败！"
  sed -i "s|ZERO_REGISTRY_NAMESPACE=.*|ZERO_REGISTRY_NAMESPACE=${ZERO_REGISTRY_NAMESPACE}|" "${ZERO_DIR}/conf/${ENV_FILE}" || log_error "替换 ZERO_REGISTRY_NAMESPACE 变量失败！"
  sed -i "s|ZERO_IMAGE_TAG=.*|ZERO_IMAGE_TAG=${ZERO_IMAGE_TAG}|" "${ZERO_DIR}/conf/${ENV_FILE}" || log_error "替换 ZERO_IMAGE_TAG 变量失败！"
  sed -i "s|MYSQL_PASSWORD=.*|MYSQL_PASSWORD=${MYSQL_PASSWORD}|" "${ZERO_DIR}/conf/${ENV_FILE}" || log_error "替换 MYSQL_PASSWORD 变量失败！"
  sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=${REDIS_PASSWORD}|" "${ZERO_DIR}/conf/${ENV_FILE}" || log_error "替换 REDIS_PASSWORD 变量失败！"
  log_debug "${ENV_FILE} 文件中的变量替换成功！"
}

# 替换变量
replace_vars() {
  # 将目录中的 ${ENV_FILE} 文件中的变量替换为实际值 APP_DIR=${ZERO_DIR}/conf DATA_DIR=${ZERO_DIR}/data LOGS_DIR=${ZERO_DIR}/logs
  log_debug "替换 ${ENV_FILE} 文件中的变量..."
  sed -i "s|APP_DIR=.*|APP_DIR=${ZERO_DIR}/conf|" "${ENV_FILE}" || log_error "替换 APP_DIR 变量失败！"
  sed -i "s|DATA_DIR=.*|DATA_DIR=${ZERO_DIR}/data|" "${ENV_FILE}" || log_error "替换 DATA_DIR 变量失败！"
  sed -i "s|LOGS_DIR=.*|LOGS_DIR=${ZERO_DIR}/logs|" "${ENV_FILE}" || log_error "替换 LOGS_DIR 变量失败！"
  sed -i "s|ZERO_DOCKER_REGISTRY=.*|ZERO_DOCKER_REGISTRY=${ZERO_DOCKER_REGISTRY}|" "${ENV_FILE}" || log_error "替换 ZERO_DOCKER_REGISTRY 变量失败！"
  sed -i "s|ZERO_REGISTRY_NAMESPACE=.*|ZERO_REGISTRY_NAMESPACE=${ZERO_REGISTRY_NAMESPACE}|" "${ENV_FILE}" || log_error "替换 ZERO_REGISTRY_NAMESPACE 变量失败！"
  sed -i "s|ZERO_IMAGE_TAG=.*|ZERO_IMAGE_TAG=${ZERO_IMAGE_TAG}|" "${ENV_FILE}" || log_error "替换 ZERO_IMAGE_TAG 变量失败！"
  sed -i "s|MYSQL_PASSWORD=.*|MYSQL_PASSWORD=${MYSQL_PASSWORD}|" "${ENV_FILE}" || log_error "替换 MYSQL_PASSWORD 变量失败！"
  sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=${REDIS_PASSWORD}|" "${ENV_FILE}" || log_error "替换 REDIS_PASSWORD 变量失败！"
  log_debug "${ENV_FILE} 文件中的变量替换成功！"
  # 修改部署时间
  log_debug "替换 ${COMPOSE_FILE} 文件中的变量..."
  sed -i "s/DT: \".*\"/DT: \"$(date '+%Y-%m-%dT%H:%M:%S')\"/g" "${COMPOSE_FILE}" || log_error "替换 ${COMPOSE_FILE} 文件中的 DT 变量失败！"
  log_debug "${COMPOSE_FILE} 文件中的变量替换成功！"
}

# 创建网络函数
create_network() {
  log_info "检查 Docker 网络 ${ZERO_NAMESPACE} ..."
  if docker network inspect "${ZERO_NAMESPACE}" &>/dev/null; then
    log_debug "Docker 网络 ${ZERO_NAMESPACE} 已存在"
  else
    log_info "创建 Docker 网络 ${ZERO_NAMESPACE} ..."
    docker network create --driver overlay "${ZERO_NAMESPACE}" || log_error "创建 Docker 网络 ${ZERO_NAMESPACE} 失败！"
    log_debug "创建 Docker 网络 ${ZERO_NAMESPACE} 成功！"
  fi
}

# 创建数据目录函数
create_volume() {
  local volume_name="$1";
  log_info "检查 Docker 数据目录 ${volume_name} ..."
  if docker volume inspect "${volume_name}" &>/dev/null; then
    log_debug "Docker 数据目录 ${volume_name} 已存在"
  else
    log_info "创建 Docker 数据目录 ${volume_name} ..."
    docker volume create --driver local --opt type=none --opt device="${ZERO_DIR}/data" --opt o=bind "${volume_name}" || log_error "创建 Docker 数据目录 ${volume_name} 失败！"
    log_debug "创建 Docker 数据目录 ${volume_name} 成功！"
  fi
}

# 准备镜像函数
prepare_image() {
  # 询问用户选择镜像模式
  log_info "请输入选项数字以选择获取镜像的方式（直接回车默认选择 pull 拉取仓库镜像）:"
  log_warn "如果当前是无网环境，请选择 skip 跳过构建镜像，同时，请准备好了离线的 docker 镜像，并且调整好各个服务的 ${COMPOSE_FILE} 配置文件中的镜像名称"
  while true; do
    echo "1) pull 拉取仓库镜像"
    echo "2) build 本地构建镜像"
    read -r -p "请选择选项 (直接回车默认为1): " choice

    if [[ -z "$choice" || "$choice" == "1" ]]; then
      IMAGE_MODE="pull"
      log_info "您选择了拉取仓库镜像..."
      break
    elif [[ "$choice" == "2" ]]; then
      IMAGE_MODE="build"
      log_info "您选择了本地构建镜像..."
      break
    else
      log_warn "无效的选项 $choice，请重新选择..."
    fi
  done

  images=(
    "zero-server"
    "zero-admin"
    )
  # 遍历镜像列表
  for image in "${images[@]}"; do
    if [ "$IMAGE_MODE" = "pull" ]; then
      pull_image "${image}"
    elif [ "$IMAGE_MODE" = "build" ]; then
      build_image "${image}"
    fi
  done
}

# 拉取镜像函数
pull_image() {
  local image_name="$1";
  log_info "开始拉取 Docker 镜像 ${image_name} ..."
  # 检查 Docker Registry 是否存在
  if [ -z "${ZERO_DOCKER_REGISTRY}" ]; then
    log_error "Docker Registry 未设置，请检查 ${ENV_FILE} 文件中的配置！"
  fi
  if [ -z "${ZERO_REGISTRY_NAMESPACE}" ]; then
    log_error "Registry Namespace 未设置，请检查 ${ENV_FILE} 文件中的配置！"
  fi
  # 如果 ZERO_REGISTRY_NAMESPACE = "ice-run-open"，则不需要登录
  if [ "${ZERO_REGISTRY_NAMESPACE}" = "ice-run-open" ]; then
    log_debug "Registry Namespace 为 ice-run-open，无需登录！"
  else
    # 尝试登录 Docker Registry
    log_info "尝试登录 Docker Registry：${ZERO_DOCKER_REGISTRY} ..."
    docker login "${ZERO_DOCKER_REGISTRY}"
  fi
  # 拉取 Docker 镜像
  log_info "拉取 Docker 镜像 ${image_name} ..."
  docker pull "${ZERO_DOCKER_REGISTRY}/${ZERO_REGISTRY_NAMESPACE}/${image_name}:${ZERO_IMAGE_TAG}" || log_error "拉取 Docker 镜像 ${image_name} 失败！"
  log_debug "拉取 Docker 镜像 ${image_name} 成功！"
  # docker tag "${ZERO_DOCKER_REGISTRY}/${ZERO_REGISTRY_NAMESPACE}/${image_name}:${ZERO_IMAGE_TAG}" "${image_name}" || log_error "标记 Docker 镜像 ${image_name} 失败！"
  # log_debug "标记 Docker 镜像 ${image_name} 成功！"
}

# 构建镜像函数
build_image() {
  local image_name="$1";
  chmod +x "${WORK_DIR}/build.sh" || log_warn "设置 build.sh 文件权限失败！"
  "${WORK_DIR}/build.sh" "${image_name}" "${ZERO_IMAGE_TAG}" || log_error "镜像构建也失败了！"
}

# 部署服务函数
deploy_service() {
  local service="$1";
  log_info "准备部署服务 ${service} ..."

  # 进入工作目录
  log_debug "切换到工作目录 ${WORK_DIR} ..."
  cd "${WORK_DIR}" || log_error "切换到工作目录 ${WORK_DIR} 失败"

  # 检查服务容器是否存在
  if docker ps -a --filter "name=${service}" --format "{{.ID}}" | grep -q .; then
    log_debug "服务容器 ${service} 已存在，跳过部署"
  else
    log_debug "创建服务容器 ${service} ..."
    # 创建 conf & data & logs 目录
    # 如果不存在，则创建，并赋予权限
    for dir in "${ZERO_DIR}/conf" "${ZERO_DIR}/data" "${ZERO_DIR}/logs"; do
      if [ ! -d "${dir}/${service}" ]; then
        log_debug "创建目录 ${dir}/${service} ..."
        mkdir -p "${dir}/${service}" || log_error "创建目录 ${dir}/${service} 失败！"
        chmod 755 "${dir}/${service}" || log_warn "设置目录 ${dir}/${service} 权限失败！"
        log_debug "目录 ${dir}/${service} 创建成功"
      else
        log_debug "目录 ${dir}/${service} 已存在"
      fi
    done

    # 复制所有文件（包括隐藏文件）
    cp -r "docker/${service}/." "${ZERO_DIR}/conf/${service}/" || log_error "复制 ${service} 相关文件失败！"

    # 切换到 conf 目录
    log_debug "切换到 ${ZERO_DIR}/conf/${service} 目录..."
    cd "${ZERO_DIR}/conf/${service}/" || log_error "切换到 ${ZERO_DIR}/conf/${service} 目录失败"

    # 替换变量
    replace_vars
    # 如果是 mysql，则需要替换密码
    if [ "$service" = "mysql" ]; then
      sed -i "s|MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=${MYSQL_PASSWORD}|" "${ENV_FILE}" || log_error "替换 MYSQL_ROOT_PASSWORD 变量失败！"
      # 如果 cpu 不支持 x86-64-v2 指令集，则尝试使用低版本镜像
      if ! check_x86_64_v2; then
        log_warn "CPU 不支持 x86-64-v2 指令集，尝试使用 mysql:8.0.27 镜像"
        sed -i "s|MYSQL_TAG=.*|MYSQL_TAG=8.0.27|" "${ENV_FILE}" || log_error "替换 MySQL 镜像失败！"
      fi
    fi

    # 检查 Compose 文件是否存在
    [ ! -f "$COMPOSE_FILE" ] && log_error "Docker Compose 文件 '$COMPOSE_FILE' 不存在"

    # log_debug "执行 Docker Compose..."
    # $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d || log_error "执行 Docker Compose 失败"
    log_debug "执行 Docker Stack..."
    docker stack deploy -c "$COMPOSE_FILE" "$service" || log_error "执行 Docker Stack 失败"
    log_info "服务容器 ${service} 创建成功！"
  fi
}

# 部署应用函数
deploy_application() {
  local application="$1";
  log_info "准备部署应用 ${application} ..."

  # 进入工作目录
  log_debug "切换到工作目录 ${WORK_DIR} ..."
  cd "${WORK_DIR}" || log_error "切换到工作目录 ${WORK_DIR} 失败！"

  # 创建 conf & data & logs 目录
  # 如果不存在，则创建，并赋予权限
  for dir in "${ZERO_DIR}/conf" "${ZERO_DIR}/data" "${ZERO_DIR}/logs"; do
    if [ ! -d "${dir}/${application}" ]; then
      log_debug "创建目录 ${dir}/${application} ..."
      mkdir -p "${dir}/${application}" || log_error "创建目录 ${dir}/${application} 失败！"
      chmod 755 "${dir}/${application}" || log_warn "设置目录 ${dir}/${application} 权限失败！"
      log_debug "目录 ${dir}/${application} 创建成功"
    else
      log_debug "目录 ${dir}/${application} 已存在"
    fi
  done

  # 复制所有文件（包括隐藏文件）
  log_debug "复制应用 ${application} 的编排文件 ..."
  cp -r "docker/${application}/." "${ZERO_DIR}/conf/${application}/" || log_error "复制 ${application} 编排文件失败！"

  # 切换到 conf 目录
  log_debug "切换到 ${ZERO_DIR}/conf/${application} 目录..."
  cd "${ZERO_DIR}/conf/${application}/" || log_error "切换到 ${ZERO_DIR}/conf/${application} 目录失败"

  # 替换变量
  replace_vars

  # 检查 Compose 文件是否存在
  [ ! -f "$COMPOSE_FILE" ] && log_error "Docker Compose 文件 '$COMPOSE_FILE' 不存在"

  #log_debug "执行 Docker Compose..."
  #$DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d || log_error "执行 Docker Compose 失败"
  log_debug "执行 Docker Stack..."
  docker stack deploy -c "$COMPOSE_FILE" "$application" || log_error "执行 Docker Stack 失败"
  log_info "应用容器 ${application} 创建成功！"
}

# Docker 部署
docker_deploy() {

  log_debug "替换 ${COMPOSE_FILE} 文件中的变量..."
  sed -i "s|\$\{ZERO_DIR\}|${ZERO_DIR}|" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 ZERO_DIR 变量失败！"
  sed -i "s|ZERO_DOCKER_REGISTRY=.*|${ZERO_DOCKER_REGISTRY}|" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 ZERO_DOCKER_REGISTRY 变量失败！"
  sed -i "s|ZERO_REGISTRY_NAMESPACE=.*|${ZERO_REGISTRY_NAMESPACE}|" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 ZERO_REGISTRY_NAMESPACE 变量失败！"
  sed -i "s|ZERO_IMAGE_TAG=.*|${ZERO_IMAGE_TAG}|" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 ZERO_IMAGE_TAG 变量失败！"
  sed -i "s|.*|${MYSQL_PASSWORD}|" "${ZERO_DIR}/conf/mysql/password.txt" || log_error "替换 MYSQL_PASSWORD 变量失败！"
  sed -i "s|\$\{MYSQL_PASSWORD\}|${MYSQL_PASSWORD}|" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 MYSQL_PASSWORD 变量失败！"
  sed -i "s|\$\{REDIS_PASSWORD\}|${REDIS_PASSWORD}|" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 REDIS_PASSWORD 变量失败！"
  log_debug "${COMPOSE_FILE} 文件中的变量替换成功！"

  log_info "准备进行 Docker 部署..."

  docker stack deploy -c "${ZERO_DIR}/conf/${COMPOSE_FILE}" "${ZERO_NAMESPACE}" || log_error "Docker Stack 部署失败！"
}

# 检查容器健康状态
service_health_check() {
  local retries=18
  local seconds=10
  local count=0
  local health=false

  local service="$1";
  log_info "准备检查服务健康状态 ${service} ..."

  while [ ${count} -lt ${retries} ]; do
    for container in $(docker ps -q --filter "name=${service}"); do
      local status
      status=$(docker inspect --format '{{.State.Health.Status}}' "${container}")
      if [ "${status}" == "healthy" ]; then
        health=true
      else
        health=false
      fi
    done
    if [ "${health}" == "true" ]; then
      log_info "服务 ${service} 健康检查成功！"
      return 0
    fi
    log_warn "服务 ${service} 健康检查失败，等待 ${seconds} 秒后重试..."
    sleep ${seconds}
    count=$((count + 1))
  done

  log_error "服务 ${service} 健康检查失败，超出最大重试次数"
}

# 主函数
main() {
  # 确保我们在正确的目录中（脚本所在目录）
  cd "$(dirname "$0")" || log_error "无法切换到脚本目录"

  # 检查 root 权限
  check_root

  # 检查系统环境
  check_os

  # 检查 Docker 环境
  check_docker

  # 提取环境变量
  parse_env

  # 解析命令行参数
  parse_args "$@"

  # 设置密码
  set_password

  # 创建目录
  create_dir

  # 创建 nfs
  create_nfs

  # 创建网络
  # create_network

  # 准备镜像
  prepare_image

  # 部署服务
#  deploy_service "mysql"
#  deploy_service "redis"

  # 部署后端应用
#  deploy_application "zero-server"

  # 部署前端应用
#  deploy_application "zero-admin"

  # 检查服务健康状态
#  service_health_check "mysql"
#  service_health_check "redis"
#  service_health_check "zero-server"
#  service_health_check "zero-admin"

  # 部署
  docker_deploy

  # 切换到 conf 目录
  log_debug "切换到 ${ZERO_DIR}/conf/ 目录..."
  cd "${ZERO_DIR}/conf/" || log_error "切换到 ${ZERO_DIR}/conf/ 目录失败"

  log_info "部署成功！！！"
  log_info "查看容器状态： docker ps -a"

  log_info "尝试访问网站： http://${HOST_IP}:80"

}

# 执行主函数
main "$@"

# 启动一个新的 shell 在 APP_DIR 目录
/bin/bash
