#!/bin/bash
set -e

# 定义颜色以提高可读性
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色
# GRAY='\033[0;90m'

# 日志函数
log_debug() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${BLUE}[DEBUG]${NC} $1"; }
log_info() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${GREEN}[ INFO]${NC} $1"; }
log_warn() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${YELLOW}[ WARN]${NC} $1"; }
log_error() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${RED}[ERROR]${NC} $1"; exit 1; }

# 默认配置变量
COMPOSE_FILE="compose.yaml"
ENV_FILE=".env"
PASSWORD_FILE="password.txt"
IMAGE_MODE="pull"

PROJECT="zero-tiny"
ZERO_DIR="/zero"

# 包管理器
PACKAGE_MANAGER=""

# 本机 IP
HOST_IP=$(hostname -I | awk '{print $1}')

# NFS 地址
ZERO_NFS_HOST="${HOST_IP}"

# 显示帮助信息
show_help() {
  echo -e "${BLUE}安装 ${PROJECT} ...${NC}"
  echo "用法: $(basename "$0") [选项]"
  echo ""
  echo "选项:"
  echo "  -h, --help                    # 显示帮助信息"
  echo "  -d, --dir                     # 指定安装目录，默认为 ${ZERO_DIR}"
  echo "  -m, --mode [pull|build]       # 镜像模式：pull 拉取仓库镜像；build 本地构建镜像 (默认: pull)"
  echo ""
  echo "示例:"
  echo "  $(basename "$0")              # 一键安装到默认目录 ${ZERO_DIR}"
  echo "  $(basename "$0") -d /test     # 一键安装到指定目录 /test"
}

# 参数处理
parse_args() {

  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      -d|--dir)
        if [ -z "$2" ]; then
          log_error "参数 -d | --dir 需要一个值"
        fi
        ZERO_DIR="$2"
        log_debug "设置安装目录为: ${ZERO_DIR}"
        shift 2
        ;;
      -m|--mode)
        if [ -z "$2" ]; then
          log_error "参数 -m | --mode 需要一个值"
        fi
        case "$2" in
          pull|build)
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
    log_error "请以 root 用户或使用 sudo 权限运行此脚本！（sudo bash $(basename "$0")）"
  fi
}

# 检查操作系统
check_os() {
  log_debug "检查操作系统..."
  local uname_s
  uname_s="$(uname -s 2>/dev/null || true)"
  if [ "$uname_s" != "Linux" ]; then
    log_error "此脚本仅支持 Linux 操作系统。"
  fi

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
  log_info "操作系统：${OS} ${VERSION}"

  # 选择包管理器
  log_debug "检查包管理器..."
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
  log_info "包管理器：${PACKAGE_MANAGER}"
}

# 判断包是否已安装
check_pkg() {
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

# 检查 curl
check_curl() {
  log_debug "检查 curl..."
  if ! command -v curl >/dev/null 2>&1; then
    log_info "curl 未安装，开始安装..."
    if ! install_pkg curl; then
      log_error "curl 安装失败，请检查系统配置！"
    fi
  else
    log_info "curl 已安装，版本：$(curl --version | head -n 1)"
  fi
}

# 检查 git
check_git() {
  log_debug "检查 git..."
  if ! command -v git >/dev/null 2>&1; then
    log_info "git 未安装，开始安装..."
    if ! install_pkg git; then
      log_error "git 安装失败，请检查系统配置！"
    fi
  else
    log_info "git 已安装，版本：$(git --version)"
  fi
}

# 检查 tar
check_tar() {
  log_info "检查 tar..."
  if ! check_pkg tar; then
    log_info "tar 未安装，开始安装..."
    if ! install_pkg tar; then
      log_error "tar 安装失败，请检查系统配置！"
    fi
  else
    log_info "tar 已安装，版本：$(tar --version | head -n 1)"
  fi
}

# 检查 Docker 是否安装
check_docker() {
  log_info "检查 Docker 环境..."
  if ! command -v docker > /dev/null 2>&1; then
    log_warn "未找到 Docker 命令。请确保 Docker 已安装并添加到 PATH 中。
    可以使用以下命令安装 Docker：
    curl -fsSL https://get.docker.com | sudo sh
    参考 Docker 官方文档： https://docs.docker.com/engine/install/
    如果出现网络错误，可以尝试多次重试，或者手动安装 Docker。"
    # 交互式安装 Docker
    read -r -p "是否要安装 Docker？ [Y/n] (直接回车默认为 Y): " install_docker
    if [[ -z "$install_docker" || "$install_docker" =~ ^[Yy]$ ]]; then
      log_info "开始安装 Docker..."
      if command -v curl > /dev/null 2>&1; then
        curl -fsSL https://get.docker.com -o get-docker.sh || log_error "下载 Docker 安装脚本失败！请检查网络连接。可以尝试多次重试"
        sh get-docker.sh || log_error "Docker 安装脚本执行失败！请检查网络连接。可以尝试多次重试"
        rm get-docker.sh || log_error "删除 Docker 安装脚本失败！请检查权限。"
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
}

# 提取 ${ENV_FILE} 文件中的变量
parse_env() {
  # 检查是否存在 ${ENV_FILE} 文件
  local env_file="${ZERO_DIR}/code/${PROJECT}/docker/$ENV_FILE"

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

  # 询问用户是否使用这些变量
  read -r -p "是否使用这些变量？ [Y/n] (直接回车默认为 Y): " use_vars
  if [[ -z "$use_vars" || "$use_vars" =~ ^[Yy]$ ]]; then
    log_info "使用变量: ZERO_DIR=${ZERO_DIR}"
  else
    log_error "用户选择不使用变量，部署终止。请调整 ${ZERO_DIR}/code/${PROJECT}/docker/${ENV_FILE} 文件中的变量后重试。"
  fi

}

# 创建工程目录
create_dir() {
  log_debug "确认安装目录..."
  read -r -p "是否确认安装到目录 ${ZERO_DIR} ？ [Y/n] (直接回车默认为 Y): " confirm
  if [[ -z "$confirm" || "$confirm" =~ ^[Yy]$ ]]; then
    log_info "用户输入了 ${confirm} 确认安装到目录 ${ZERO_DIR}"
  else
    # 循环请求用户输入，直到满足要求
    while true; do
      read -r -p "请输入安装目录: " input_dir
      if [ -z "$input_dir" ]; then
        log_warn "安装目录不能为空！请重新输入..."
      elif ! [[ "$input_dir" =~ ^/[a-zA-Z0-9_/-]+$ ]]; then
        log_warn "安装目录必须符合正则表达式 ^/[a-zA-Z0-9_/-]+$ ！请重新输入..."
      else
        ZERO_DIR="$input_dir"
        log_info "使用用户输入的安装目录: ${ZERO_DIR}"
        break
      fi
    done
  fi

  log_info "创建工程目录 ${ZERO_DIR} ..."
  if [ -d "${ZERO_DIR}" ]; then
    log_warn "目录 ${ZERO_DIR} 已存在，跳过创建"
    # 检查目录权限
    if [ ! -w "${ZERO_DIR}" ] || [ ! -x "${ZERO_DIR}" ]; then
      log_warn "对目录 ${ZERO_DIR} 没有写入或执行权限！"
      log_debug "尝试修改目录 ${ZERO_DIR} 的权限..."
      chmod u+w+x "${ZERO_DIR}" || log_error "无法修改目录 ${ZERO_DIR} 的权限！请手动检查权限设置。"
      log_info "目录 ${ZERO_DIR} 权限修改成功"
    fi
  else
    mkdir -p "${ZERO_DIR}" || log_error "无法创建目录 ${ZERO_DIR} ！"
    log_info "目录 ${ZERO_DIR} 创建成功"
  fi

  log_info "准备创建目录并赋予权限..."
  local dirs=("${ZERO_DIR}/code" "${ZERO_DIR}/conf" "${ZERO_DIR}/data" "${ZERO_DIR}/logs")
  local names=("code" "conf" "data" "logs")

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

  # 创建 ${ZERO_DIR}/data/mysql 目录
  log_info "创建 ${ZERO_DIR}/data/mysql 目录..."
  mkdir -p "${ZERO_DIR}/data/mysql" || log_error "创建 ${ZERO_DIR}/data/mysql 目录失败！"
  chmod 755 "${ZERO_DIR}/data/mysql" || log_warn "设置 ${ZERO_DIR}/data/mysql 目录权限失败！"
  log_debug "${ZERO_DIR}/data/mysql 目录创建成功"

  # 创建 ${ZERO_DIR}/data/redis 目录
  log_info "创建 ${ZERO_DIR}/data/redis 目录..."
  mkdir -p "${ZERO_DIR}/data/redis" || log_error "创建 ${ZERO_DIR}/data/redis 目录失败！"
  chmod 755 "${ZERO_DIR}/data/redis" || log_warn "设置 ${ZERO_DIR}/data/redis 目录权限失败！"
  log_debug "${ZERO_DIR}/data/redis 目录创建成功"

  # 创建 ${ZERO_DIR}/data/server 目录
  log_info "创建 ${ZERO_DIR}/data/server 目录..."
  mkdir -p "${ZERO_DIR}/data/server" || log_error "创建 ${ZERO_DIR}/data/server 目录失败！"
  chmod 755 "${ZERO_DIR}/data/server" || log_warn "设置 ${ZERO_DIR}/data/server 目录权限失败！"
  log_debug "${ZERO_DIR}/data/server 目录创建成功"

  # 创建 ${ZERO_DIR}/logs/server 目录
  log_info "创建 ${ZERO_DIR}/logs/server 目录..."
  mkdir -p "${ZERO_DIR}/logs/server" || log_error "创建 ${ZERO_DIR}/logs/server 目录失败！"
  chmod 777 "${ZERO_DIR}/logs/server" || log_warn "设置 ${ZERO_DIR}/logs/server 目录权限失败！"
  log_debug "${ZERO_DIR}/logs/server 目录创建成功"

}

# 克隆代码仓库
git_clone() {
  log_debug "切换到 ${ZERO_DIR}/code/ 目录..."
  cd "${ZERO_DIR}/code/" || log_error "切换到 ${ZERO_DIR}/code/ 目录失败"

  log_info "开始克隆代码仓库..."
  if [ -d "${ZERO_DIR}/code/${PROJECT}" ]; then
    log_warn "代码仓库 ${PROJECT} 已存在，尝试更新代码..."
    cd "${ZERO_DIR}/code/${PROJECT}" || log_error "无法切换到代码目录 ${ZERO_DIR}/code/${PROJECT} ！"
    git reset --hard HEAD || log_error "代码仓库重置失败，请检查代码仓库状态！"
    git pull origin master || log_error "代码仓库更新失败，请检查网络或仓库状态！"
    log_info "代码仓库更新成功！"
  else
    git clone https://gitee.com/ice-run/zero-tiny.git || log_error "代码仓库克隆失败，请检查网络或仓库状态！"
    git config --global --add safe.directory "${ZERO_DIR}/code/${PROJECT}"
    log_info "代码仓库克隆成功！"
  fi
}

# 复制配置文件
copy_config() {
  log_info "复制 ${ZERO_DIR}/code/${PROJECT}/docker 目录中的所有文件到 ${ZERO_DIR}/conf ..."
  cp -a "${ZERO_DIR}/code/${PROJECT}/docker/." "${ZERO_DIR}/conf/" || log_error "复制 docker 目录文件失败！"
  log_debug "配置文件复制成功！！！"
  log_debug "替换 ${ENV_FILE} 文件中的变量..."
  sed -i "s|ZERO_DIR=.*|ZERO_DIR=${ZERO_DIR}|g" "${ZERO_DIR}/conf/${ENV_FILE}" || log_error "替换 ZERO_DIR 变量失败！"
}

# 设置密码函数
set_password() {
  # 优先从 ${ZERO_DIR}/conf/mysql/${PASSWORD_FILE} 读取已存在的 MYSQL_PASSWORD
  if [ -z "$MYSQL_PASSWORD" ]; then
    if [ -f "${ZERO_DIR}/conf/mysql/${PASSWORD_FILE}" ]; then
      MYSQL_PASSWORD=$(cat "${ZERO_DIR}/conf/mysql/${PASSWORD_FILE}")
    fi
  fi

  # 设置 MySQL 密码
  if [ -z "$MYSQL_PASSWORD" ]; then
    log_info "随机生成 MySQL 密码，或者手动输入密码..."
    read -r -p "是否随机生成 MySQL 密码？ [Y/n] (直接回车默认为 Y): " generate_password
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


  # 优先从 ${ZERO_DIR}/conf/redis/${PASSWORD_FILE} 读取已存在的 REDIS_PASSWORD
  if [ -z "$REDIS_PASSWORD" ]; then
    if [ -f "${ZERO_DIR}/conf/redis/${PASSWORD_FILE}" ]; then
      REDIS_PASSWORD=$(cat "${ZERO_DIR}/conf/redis/${PASSWORD_FILE}")
    fi
  fi

  # 设置 Redis 密码
  if [ -z "$REDIS_PASSWORD" ]; then
    log_info "随机生成 Redis 密码，或者手动输入密码..."
    read -r -p "是否随机生成 Redis 密码？ [Y/n] (直接回车默认为 Y): " generate_password
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
  if ! check_pkg "$pkg"; then
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
        if systemctl enable --now "$found_svc" >/dev/null 2>&1; then
          log_info "NFS 服务 ${found_svc} 启动成功"
        else
          log_warn "NFS 服务 ${found_svc} 启动失败，请稍后检查"
        fi
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
  [ -d "${ZERO_DIR}" ] || { mkdir -p "${ZERO_DIR}" || log_error "创建目录 ${ZERO_DIR} 失败"; chmod 755 "${ZERO_DIR}" || true; }

  # 配置 /etc/exports（幂等）
  exports_file="/etc/exports"
  opts="rw,sync,no_subtree_check,no_root_squash"
  backup_ts=$(date +%s)
  if [ -f "$exports_file" ]; then
    cp "$exports_file" "${exports_file}.bak.${backup_ts}" 2>/dev/null || true
  fi

  # 转义路径用于正则
  esc_dir=$(printf '%s' "${ZERO_DIR}" | sed -e 's/[].[^$\\*/]/\\&/g')
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

# 准备镜像函数
prepare_image() {
  # 询问用户选择镜像模式
  log_info "请输入选项数字以选择获取镜像的方式（直接回车默认选择 pull 拉取仓库镜像）:"
  while true; do
    echo "1) pull 拉取仓库镜像"
    echo "2) build 本地构建镜像"
    read -r -p "请选择选项 [1/2] (直接回车默认为 1): " choice

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
  build_script="${ZERO_DIR}/code/${PROJECT}/build.sh"
  chmod +x "${build_script}" || log_warn "设置 build.sh 文件权限失败！"
  "${build_script}" "${image_name}" "${ZERO_IMAGE_TAG}" || log_error "镜像构建也失败了！"
}

# Docker 部署
docker_deploy() {

  log_debug "替换 ${COMPOSE_FILE} 文件中的变量..."
  sed -i "s|\${ZERO_DIR}|${ZERO_DIR}|g" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 ZERO_DIR 变量失败！"
  sed -i "s|\${ZERO_DOCKER_REGISTRY}|${ZERO_DOCKER_REGISTRY}|g" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 ZERO_DOCKER_REGISTRY 变量失败！"
  sed -i "s|\${ZERO_REGISTRY_NAMESPACE}|${ZERO_REGISTRY_NAMESPACE}|g" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 ZERO_REGISTRY_NAMESPACE 变量失败！"
  sed -i "s|\${ZERO_IMAGE_TAG}|${ZERO_IMAGE_TAG}|g" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 ZERO_IMAGE_TAG 变量失败！"
  sed -i "s|.*|${MYSQL_PASSWORD}|g" "${ZERO_DIR}/conf/mysql/${PASSWORD_FILE}" || log_error "替换 MYSQL_PASSWORD 变量失败！"
  sed -i "s|.*|${REDIS_PASSWORD}|g" "${ZERO_DIR}/conf/redis/${PASSWORD_FILE}" || log_error "替换 REDIS_PASSWORD 变量失败！"
  sed -i "s|\${MYSQL_PASSWORD}|${MYSQL_PASSWORD}|g" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 MYSQL_PASSWORD 变量失败！"
  sed -i "s|\${REDIS_PASSWORD}|${REDIS_PASSWORD}|g" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 REDIS_PASSWORD 变量失败！"
  sed -i "s|\${ZERO_NFS_HOST}|${ZERO_NFS_HOST}|g" "${ZERO_DIR}/conf/${COMPOSE_FILE}" || log_error "替换 ZERO_NFS_HOST 变量失败！"
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

  # 解析命令行参数
  parse_args "$@"

  # 检查 root 权限
  check_root

  # 检查系统环境
  check_os

  # 检查 curl
  check_curl

  # 检查 git
  check_git

  # 检查 tar
  check_tar

  # 检查 Docker 环境
  check_docker

  # 创建工程目录
  create_dir

  # 克隆代码仓库
  git_clone

  # 复制配置文件
  copy_config

  # 提取环境变量
  parse_env

  # 设置密码
  set_password

  # 创建 nfs
  create_nfs

  # 准备镜像
  prepare_image

  # 部署
  docker_deploy

  # 切换到工程目录
  log_debug "切换到 ${ZERO_DIR} 目录..."
  cd "${ZERO_DIR}" || log_error "切换到 ${ZERO_DIR} 目录失败"

  log_info "部署成功！！！"
  log_info "查看容器状态： docker service ls"
  log_info "尝试访问网站： http://${HOST_IP}:80"
  log_info "安装完成！！！"
}

# 执行主函数
main "$@"
