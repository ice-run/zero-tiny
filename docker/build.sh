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
ENV_FILE=".env"

PROJECT="zero-tiny"
ZERO_DOCKER_REGISTRY=""
ZERO_REGISTRY_NAMESPACE=""
ZERO_APPLICATION=""
ZERO_IMAGE_TAG="tiny-latest"

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
  ZERO_DIR="$(pwd)"
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
  ZERO_APPLICATION="$1"
  # 设置镜像标签（第二个位置参数）
  if [ $# -eq 1 ]; then
    ZERO_IMAGE_TAG="tiny-latest"
  else
    # 如果镜像标签以 tiny- 开头，直接使用
    if [[ "$2" == tiny-* ]]; then
      ZERO_IMAGE_TAG="$2"
    else
      # 如果镜像标签不以 tiny- 开头，添加 tiny- 前缀
      ZERO_IMAGE_TAG="tiny-$2"
    fi
  fi

  # 验证应用名称不为空
  if [ -z "${ZERO_APPLICATION}" ]; then
    log_error "应用名称不能为空"
  fi

  # 验证镜像标签不为空
  if [ -z "${ZERO_IMAGE_TAG}" ]; then
    log_error "镜像标签不能为空"
  fi
}

# 提取 ${ENV_FILE} 文件中的变量
parse_env() {
  # 检查是否存在 ${ENV_FILE} 文件
  local env_file="${ZERO_DIR}/conf/${ENV_FILE}"

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
  log_info "变量值: ZERO_DIR=${ZERO_DIR}"
}

# 切换工程目录
switch_code_dir() {
  log_debug "切换到工程目录 ${ZERO_DIR} ..."
  cd "${ZERO_DIR}" || log_error "无法切换到工程目录 ${ZERO_DIR} ！"
}

# docker build
docker_build() {
  local module_dir
  case "${ZERO_APPLICATION}" in
    "zero-admin")
      module_dir="admin"
      ;;
    "zero-server")
      module_dir="server"
      ;;
    *)
      log_error "无效的应用名称 ${ZERO_APPLICATION}！"
      ;;
  esac

  local app_dir="${ZERO_DIR}/code/${PROJECT}/${module_dir}"

  log_info "docker build ${ZERO_APPLICATION}:${ZERO_IMAGE_TAG} ..."
  docker build -f "${app_dir}/Dockerfile" -t "${ZERO_DOCKER_REGISTRY}/${ZERO_REGISTRY_NAMESPACE}/${ZERO_APPLICATION}:${ZERO_IMAGE_TAG}" "${app_dir}" || log_error "docker build 失败！"
}

# docker push
docker_push() {
  log_info "docker push ${ZERO_APPLICATION}:${ZERO_IMAGE_TAG} ..."
  # 尝试登录 Docker Registry
  log_info "尝试登录 Docker Registry：${ZERO_DOCKER_REGISTRY} ..."
  if docker login "${ZERO_DOCKER_REGISTRY}"; then
    # 登录成功，执行推送
    log_info "Docker Registry 登录成功，开始推送镜像..."
    docker push "${ZERO_DOCKER_REGISTRY}/${ZERO_REGISTRY_NAMESPACE}/${ZERO_APPLICATION}:${ZERO_IMAGE_TAG}" || log_error "docker push 失败！"
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

  # 解析环境变量
  parse_env

  # docker build
  docker_build

  # docker push
  # 开源版本暂不推送镜像，开发者可自行修改仓库地址和脚本
  # docker_push

  log_info "${ZERO_DOCKER_REGISTRY}/${ZERO_REGISTRY_NAMESPACE}/${ZERO_APPLICATION}:${ZERO_IMAGE_TAG} 构建成功！"
}

# 执行主函数
main "$@"
