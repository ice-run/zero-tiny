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

PROJECT_NAME="zero-tiny"
ZERO_DIR="/zero"

# 包管理器
PACKAGE_MANAGER=""

# 显示帮助信息
show_help() {
  echo -e "${BLUE}安装 ${PROJECT_NAME} ...${NC}"
  echo "用法: $(basename "$0") [选项]"
  echo ""
  echo "选项:"
  echo "  -h, --help                    # 显示帮助信息"
  echo "  -d, --dir                     # 指定安装目录，默认为 ${ZERO_DIR}"
  echo ""
  echo "示例:"
  echo "  $(basename "$0")              # 一键安装到默认目录 ${ZERO_DIR}"
  echo "  $(basename "$0") -d /test     # 一键安装到指定目录 /test"
}

# 参数处理
parse_args() {
  # WORK_DIR="$(pwd)"

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
}

# 克隆代码仓库
git_clone() {
  log_info "创建代码仓库目录 ${ZERO_DIR}/code ..."
  mkdir -p "${ZERO_DIR}/code" || log_error "无法创建目录 ${ZERO_DIR}/code ！"

  log_debug "切换到 ${ZERO_DIR}/code/ 目录..."
  cd "${ZERO_DIR}/code/" || log_error "切换到 ${ZERO_DIR}/code/ 目录失败"

  log_info "开始克隆代码仓库..."
  if [ -d "${ZERO_DIR}/code/${PROJECT_NAME}" ]; then
    log_warn "代码仓库 ${PROJECT_NAME} 已存在，尝试更新代码..."
    cd "${ZERO_DIR}/code/${PROJECT_NAME}" || log_error "无法切换到代码目录 ${ZERO_DIR}/code/${PROJECT_NAME} ！"
    git reset --hard HEAD || log_error "代码仓库重置失败，请检查代码仓库状态！"
    git pull origin master || log_error "代码仓库更新失败，请检查网络或仓库状态！"
    log_info "代码仓库更新成功！"
  else
    git clone https://gitee.com/ice-run/zero-tiny.git || log_error "代码仓库克隆失败，请检查网络或仓库状态！"
    git config --global --add safe.directory "${ZERO_DIR}/code/${PROJECT_NAME}"
    log_info "代码仓库克隆成功！"
  fi
}

# 执行部署脚本
run_deploy() {
  log_info "准备执行部署脚本..."
  deploy_script="${ZERO_DIR}/code/${PROJECT_NAME}/deploy.sh"
  if [ -f "$deploy_script" ]; then
    chmod +x "$deploy_script" || log_warn "无法设置部署脚本可执行权限，但仍尝试运行..."
    log_info "正在执行部署脚本 bash $deploy_script ..."
    bash "$deploy_script" || log_error "部署脚本执行失败！可以重试部署命令: bash $deploy_script"
    log_info "部署脚本执行成功！"
  else
    log_error "部署脚本 $deploy_script 不存在，无法继续！"
  fi
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

  # 创建工程目录
  create_dir

  # 克隆代码仓库
  git_clone

  # 执行部署脚本
  run_deploy

  cd "${ZERO_DIR}" || log_error "无法切换到安装目录 ${ZERO_DIR} ！"
  log_info "安装完成！"
}

# 执行主函数
main "$@"
