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
MODE="RESTART"
DOCKER_REGISTRY=""
REGISTRY_NAMESPACE=""
NAMESPACE="zero"
COMPOSE_FILE="compose.yaml"
ENV_FILE=".env"
APPLICATION=""
IMAGE_TAG="latest"
CODE_DIR="/app/zero-tiny"

# 显示帮助信息
show_help() {
  echo -e "${BLUE}Docker 部署脚本${NC}"
  echo "用法: $(basename "$0") <应用名称> [镜像标签]"
  echo ""
  echo "参数:"
  echo "  <应用名称>        # 部署的应用名称（必需）"
  echo "  [镜像标签]        # 部署的镜像标签（可选）"
  echo ""
  echo "模式说明:"
  echo "  重启模式：        # 只传一个参数，仅更新部署时间并重启服务"
  echo "  更新模式：        # 传两个参数，更新镜像版本和部署时间"
  echo ""
  echo "选项:"
  echo "  -h, --help        # 显示帮助信息"
  echo ""
  echo "示例:"
  echo "  $(basename "$0") demo                  # 重启 demo 应用（不更新版本）"
  echo "  $(basename "$0") demo 250101-0         # 更新 demo 应用到版本 250101-0"
}

# 参数处理
parse_args() {
  WORK_DIR="$(pwd)"
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

  # 判断模式和设置镜像标签
  if [ $# -eq 1 ]; then
    # 重启模式：只有一个参数
    MODE="RESTART"
    log_info "重启模式：仅更新部署时间并重启服务"
  else
    # 更新模式：有两个参数
    MODE="UPDATE"
    IMAGE_TAG="$2"
    log_info "更新模式：更新镜像版本到 ${IMAGE_TAG}"
  fi

  # 验证应用名称不为空
  if [ -z "${APPLICATION}" ]; then
    log_error "应用名称不能为空"
  fi
}

# 提取 ${ENV_FILE} 文件中的变量
parse_env() {
  # 检查是否存在 ${ENV_FILE} 文件
  local env_file="${ENV_FILE}"

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
  log_info "变量值: CODE_DIR=${CODE_DIR}"
}

# 准备镜像
prepare_image() {
  log_info "准备镜像 ${DOCKER_REGISTRY}/${REGISTRY_NAMESPACE}/${APPLICATION}:${IMAGE_TAG} ..."
  if docker pull "${DOCKER_REGISTRY}/${REGISTRY_NAMESPACE}/${APPLICATION}:${IMAGE_TAG}"; then
    log_info "docker pull 成功，已获取指定镜像！"
  else
    log_warn "docker pull 失败，尝试本地构建镜像..."
    local code_dir="${CODE_DIR}"
    if [ -z "${code_dir}" ]; then
      log_error "未找到 CODE_DIR 环境变量"
    fi
    if [ ! -d "${code_dir}" ]; then
      log_error "代码目录 ${code_dir} 不存在"
    fi
    if [ ! -f "${code_dir}/build.sh" ]; then
      log_error "代码目录 ${code_dir} 中不存在 build.sh 脚本"
    fi

    switch_code_dir

    # git 拉取最新代码
    git_pull

    sh "${code_dir}/build.sh" "${APPLICATION}" "${IMAGE_TAG}" || log_error "镜像构建也失败了！"
  fi
}

# git 拉取最新代码
git_pull() {
  # 切换工程目录
  switch_code_dir
  # 检查是否为 git 仓库
  if [ ! -d ".git" ]; then
    log_error "当前目录不是 git 仓库"
  fi
  log_info "git 拉取最新代码 ..."
  git pull origin master || log_error "git 拉取最新代码失败！"
}

# 切换代码目录
switch_code_dir() {
  log_debug "切换到代码目录 ${CODE_DIR} ..."
  if [ ! -d "${CODE_DIR}" ]; then
    log_error "代码目录 ${CODE_DIR} 不存在"
  fi
  cd "${CODE_DIR}" || log_error "无法切换到代码目录 ${CODE_DIR} ！"
}

# 切换应用目录
switch_app_dir() {
  log_debug "切换到应用目录 ${WORK_DIR}/${APPLICATION} ..."
  local app_dir="${WORK_DIR}/${APPLICATION}"
  if [ ! -d "${app_dir}" ]; then
    log_error "应用目录 ${app_dir} 不存在"
  fi
  cd "${app_dir}" || log_error "无法切换到应用目录 ${app_dir} ！"
}

# 切换工作目录
switch_work_dir() {
  log_debug "切换到工作目录 ${WORK_DIR} ..."
  if [ ! -d "${WORK_DIR}" ]; then
    log_error "工作目录 ${WORK_DIR} 不存在！"
  fi
  cd "${WORK_DIR}" || log_error "无法切换到工作目录 ${WORK_DIR} ！"
}

# 更新环境变量文件
update_env_file() {
  if [ "${MODE}" = "RESTART" ]; then
    log_debug "重启模式：跳过环境变量文件更新"
    return 0
  fi

  log_info "更新环境变量文件 ${ENV_FILE} ..."
  if [ ! -f "${ENV_FILE}" ]; then
    log_error "环境变量文件 ${ENV_FILE} 不存在！"
  fi

  # 替换镜像标签
  sed -i "s|^IMAGE_TAG=.*|IMAGE_TAG=${IMAGE_TAG}|g" "${ENV_FILE}"
}

# 更新编排文件
update_compose_file() {
  log_info "更新编排文件 ${COMPOSE_FILE} ..."
  if [ ! -f "${COMPOSE_FILE}" ]; then
    log_error "编排文件 ${COMPOSE_FILE} 不存在！"
  fi

  # 只在更新模式下替换镜像标签
  if [ "${MODE}" = "UPDATE" ]; then
    sed -i "s|\(image: .*/${REGISTRY_NAMESPACE}/${APPLICATION}:\).*|\1${IMAGE_TAG}|g" "${COMPOSE_FILE}"
  fi

  # 无论哪种模式都修改部署时间
  sed -i "s/DT: \".*\"/DT: \"$(date '+%Y-%m-%dT%H:%M:%S')\"/g" "${COMPOSE_FILE}"
}

# 执行 docker compose
docker_compose_up() {
  log_info "执行 docker compose up ..."
  docker compose -f "${COMPOSE_FILE}" up -d || log_error "docker compose 执行失败！"
  log_info "docker compose 执行成功！"
}

# 检查容器健康状态
service_health_check() {
  local retries=12
  local seconds=10
  local count=0
  local health=false

  while [ ${count} -lt ${retries} ]; do
    for container in $(docker ps -q --filter "name=${APPLICATION}"); do
      local status
      status=$(docker inspect --format '{{.State.Health.Status}}' "${container}")
      if [ "${status}" == "healthy" ]; then
        health=true
      else
        health=false
      fi
    done
    if [ "${health}" == "true" ]; then
      log_info "服务 ${APPLICATION} 健康检查成功！"
      return 0
    fi
    log_warn "服务 ${APPLICATION} 健康检查失败，等待 ${seconds} 秒后重试..."
    sleep ${seconds}
    count=$((count + 1))
  done

  log_error "服务 ${APPLICATION} 健康检查失败，超出最大重试次数"
}

# 主函数
main() {
  # 确保我们在正确的目录中（脚本所在目录）
  cd "$(dirname "$0")" || log_error "无法切换到脚本目录"

  # 解析环境变量
  parse_env

  # 解析命令行参数
  parse_args "$@"

  # 准备镜像
  if [ "${MODE}" = "UPDATE" ]; then
    prepare_image
  fi

  # 切换应用目录
  switch_app_dir

  # 更新环境变量
  update_env_file

  # 更新编排文件
  update_compose_file

  # 执行 docker compose
  docker_compose_up

  # 检查 docker 容器健康状态
  service_health_check

  # 切换工作目录
  switch_work_dir

  if [ "${MODE}" = "RESTART" ]; then
    log_info "${APPLICATION} 重启成功！"
  else
    log_info "${APPLICATION}:${IMAGE_TAG} 部署成功！"
  fi
}

# 执行主函数
main "$@"
