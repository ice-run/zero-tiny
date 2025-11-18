#!/bin/bash
set -e

# 定义颜色以提高可读性
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色
# GRAY='\033[0;90m'

# 日志函数
log_debug() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${BLUE}[DEBUG]${NC} $1"; }
log_info() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${GREEN}[ INFO]${NC} $1"; }
log_warn() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${YELLOW}[ WARN]${NC} $1"; }
log_error() { echo -e "${NC}$(date '+%Y-%m-%dT%H:%M:%S') ${RED}[ERROR]${NC} $1"; exit 1; }

# 默认配置变量
MODE="RESTART"
COMPOSE_FILE="compose.yaml"
ENV_FILE=".env"

PROJECT="zero-tiny"
ZERO_DOCKER_REGISTRY=""
ZERO_REGISTRY_NAMESPACE=""
ZERO_APPLICATION=""
ZERO_IMAGE_TAG="tiny-latest"

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

  # 判断模式和设置镜像标签
  if [ $# -eq 1 ]; then
    # 重启模式：只有一个参数
    MODE="RESTART"
    log_info "重启模式：仅更新部署时间并重启服务"
  else
    # 更新模式：有两个参数
    MODE="UPDATE"
    ZERO_IMAGE_TAG="$2"
    log_info "更新模式：更新镜像版本到 ${ZERO_IMAGE_TAG}"
  fi

  # 验证应用名称不为空
  if [ -z "${ZERO_APPLICATION}" ]; then
    log_error "应用名称不能为空"
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

# 准备镜像
prepare_image() {
  log_info "准备镜像 ${ZERO_DOCKER_REGISTRY}/${ZERO_REGISTRY_NAMESPACE}/${ZERO_APPLICATION}:${ZERO_IMAGE_TAG} ..."
  if docker pull "${ZERO_DOCKER_REGISTRY}/${ZERO_REGISTRY_NAMESPACE}/${ZERO_APPLICATION}:${ZERO_IMAGE_TAG}"; then
    log_info "docker pull 成功，已获取指定镜像！"
  else
    log_warn "docker pull 失败，尝试本地构建镜像..."

    # git 拉取最新代码
    git_pull

    # 构建镜像
    local build_script="build.sh"
    chmod +x "${ZERO_DIR}/${build_script}" || log_warn "设置 ${build_script} 文件权限失败！"
    cd "${ZERO_DIR}"
    "./${build_script}" "${ZERO_APPLICATION}" "${ZERO_IMAGE_TAG}" || log_error "镜像构建也失败了！"
  fi
}

# git 拉取最新代码
git_pull() {
  cd "${ZERO_DIR}/code/${PROJECT}" || log_error "无法切换到代码目录 ${ZERO_DIR}/code/${PROJECT} ！"
  git reset --hard HEAD || log_error "代码仓库重置失败，请检查代码仓库状态！"
  git pull origin master || log_error "代码仓库更新失败，请检查网络或仓库状态！"
  log_info "代码仓库更新成功！"

  cd "${ZERO_DIR}" || log_error "无法切换到工程目录 ${ZERO_DIR} ！"
}

# 更新编排文件
update_compose_file() {
  log_info "更新编排文件 ${ZERO_DIR}/conf/${COMPOSE_FILE} ..."
  if [ ! -f "${ZERO_DIR}/conf/${COMPOSE_FILE}" ]; then
    log_error "编排文件 ${ZERO_DIR}/conf/${COMPOSE_FILE} 不存在！"
  fi

  # 只在更新模式下替换镜像标签
  if [ "${MODE}" = "UPDATE" ]; then
    sed -i "s|\(image: .*/${ZERO_REGISTRY_NAMESPACE}/${ZERO_APPLICATION}:\).*|\1${ZERO_IMAGE_TAG}|g" "${ZERO_DIR}/conf/${COMPOSE_FILE}"
  fi
}

# 执行 docker stack deploy
docker_stack_deploy() {
  log_info "执行 docker stack deploy 部署 Stack ${ZERO_NAMESPACE} ..."
  docker stack deploy -c "${ZERO_DIR}/conf/${COMPOSE_FILE}" "${ZERO_NAMESPACE}" || log_error "docker stack deploy 失败！"
}

# 执行 docker service update（仅更新部署时间）
docker_service_update() {
  log_info "执行 docker service update 重启 Stack ${ZERO_NAMESPACE} 中的服务 ${ZERO_APPLICATION} ..."
  docker service update --detach --force "${ZERO_NAMESPACE}_${ZERO_APPLICATION}" || log_error "docker service update 失败！"
}

# 检查容器健康状态
check_stack_health() {
  local retries=30
  local delay=10

  log_info "开始检查 Stack ${ZERO_NAMESPACE} 的健康状态..."
  local all
  all=$(docker stack services "${ZERO_NAMESPACE}"  --format '{{.Name}}' | wc -l | xargs)

  for ((i=1; i<=retries; i++)); do
    # 统计未就绪服务数量（避免在空输出来触发 set -e）
    local unhealthy
    unhealthy=$(
      docker stack services "${ZERO_NAMESPACE}" --format '{{.Replicas}}' | awk -F/ '($1=="N/A")||($2=="")||($1!=$2){u++} END{print u+0}'
    )

    if [[ "${unhealthy}" -eq 0 ]]; then
      log_info "Stack ${ZERO_NAMESPACE} 中所有服务都已健康运行！"
      return 0
    fi

    log_debug "第 ${i}/${retries} 次检查：仍有 ${unhealthy}/${all} 个服务未就绪..."
    sleep "${delay}"
  done

  docker stack services "${ZERO_NAMESPACE}"
  log_error "Stack ${ZERO_NAMESPACE} 部署超时，部分服务未正常启动！"
}

# 主函数
main() {
  # 确保我们在正确的目录中（脚本所在目录）
  cd "$(dirname "$0")" || log_error "无法切换到脚本目录"

  # 解析命令行参数
  parse_args "$@"

  # 解析环境变量
  parse_env

  # 准备镜像
  if [ "${MODE}" = "UPDATE" ]; then

    prepare_image

    # 更新编排文件
    update_compose_file

    # 执行 docker stack deploy
    docker_stack_deploy

  elif [ "${MODE}" = "RESTART" ]; then
    docker_service_update
  else
    log_error "未知模式：${MODE}"
  fi

  # 检查 Stack 健康状态
  check_stack_health

  if [ "${MODE}" = "RESTART" ]; then
    log_info "${ZERO_APPLICATION} 重启成功！"
  else
    log_info "${ZERO_APPLICATION}:${ZERO_IMAGE_TAG} 部署成功！"
  fi
}

# 执行主函数
main "$@"
