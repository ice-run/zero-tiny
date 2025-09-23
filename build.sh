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
DOCKER_REGISTRY="crpi-lqf79pij6cz4kaey.cn-beijing.personal.cr.aliyuncs.com"
REGISTRY_NAMESPACE="ice-run-open"
APPLICATION=""
IMAGE_TAG="latest"

# 显示帮助信息
show_help() {
  echo -e "${BLUE}Docker 构建脚本${NC}"
  echo "用法: $(basename "$0") <应用名称> [镜像标签]"
  echo ""
  echo "参数:"
  echo "  <应用名称>        # 部署的应用名称（必需）"
  echo "  [镜像标签]        # 部署的镜像标签（可选）"
  echo ""
  echo "选项:"
  echo "  -h, --help       # 显示帮助信息"
  echo ""
  echo "示例:"
  echo "  $(basename "$0") demo 250101-0  # 构建 demo 镜像标签 250101-0"
}

# 参数处理
parse_args() {
  PROJECT_DIR="$(pwd)"
  # 检查是否请求帮助
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
  fi

  # 检查参数数量
  if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    log_error "参数数量错误。请使用 -h 或 --help 查看帮助信息"
  fi

  # 设置应用名称（第一个位置参数）
  APPLICATION="$1"
  # 设置镜像标签（第二个位置参数）
  if [ $# -eq 1 ]; then
    IMAGE_TAG="latest"
  else
    IMAGE_TAG="$2"
  fi

  # 验证应用名称不为空
  if [ -z "${APPLICATION}" ]; then
    log_error "应用名称不能为空"
  fi

  # 验证镜像标签不为空
  if [ -z "${IMAGE_TAG}" ]; then
    log_error "镜像标签不能为空"
  fi
}

# 切换工程目录
switch_project_dir() {
  log_debug "切换到工程目录 ${PROJECT_DIR} ..."
  cd "${PROJECT_DIR}" || log_error "无法切换到工程目录 ${PROJECT_DIR} ！"
}

# 切换应用目录
switch_app_dir() {
  # 根据 APPLICATION 切换应用目录
  local module_dir
  case "${APPLICATION}" in
    "zero-admin")
      module_dir="zero-admin"
      ;;
    "zero-server")
      module_dir="zero-server"
      ;;
    *)
      log_error "无效的应用名称 ${APPLICATION}！"
      ;;
  esac

  local app_dir="${PROJECT_DIR}/${module_dir}"
  log_debug "切换到应用目录 ${app_dir} ..."
  if [ ! -d "${app_dir}" ]; then
    log_error "应用目录 ${app_dir} 不存在"
  fi
  cd "${app_dir}" || log_error "无法切换到应用目录 ${app_dir} ！"
}

# docker build
docker_build() {
  switch_app_dir

  log_info "docker build ..."
  docker build -f Dockerfile -t "${DOCKER_REGISTRY}/${REGISTRY_NAMESPACE}/${APPLICATION}:${IMAGE_TAG}" . || log_error "docker build 失败！"
}

# docker push
docker_push() {
  log_info "docker push ..."
  # 尝试登录 Docker Registry
  log_info "尝试登录 Docker Registry：${DOCKER_REGISTRY} ..."
  if docker login ${DOCKER_REGISTRY}; then
    # 登录成功，执行推送
    log_info "Docker Registry 登录成功，开始推送镜像..."
    docker push "${DOCKER_REGISTRY}/${REGISTRY_NAMESPACE}/${APPLICATION}:${IMAGE_TAG}" || log_error "docker push 失败！"
  else
    # 登录失败，输出警告但不中断执行
    log_warn "Docker Registry 登录失败，跳过镜像推送步骤！"
  fi
}

# 主函数
main() {
  # 确保我们在正确的目录中（脚本所在目录）
  cd "$(dirname "$0")" || log_error "无法切换到脚本目录"

  # 解析命令行参数
  parse_args "$@"

  # docker build
  docker_build

  # docker push
  # 开源版本暂不推送镜像，开发者可自行修改仓库地址和脚本
  # docker_push

  # 切换工程目录
  switch_project_dir

  log_info "${DOCKER_REGISTRY}/${REGISTRY_NAMESPACE}/${APPLICATION}:${IMAGE_TAG} 构建成功！"
}

# 执行主函数
main "$@"
