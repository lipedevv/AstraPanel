#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PROJECT_DIR
readonly BASE_COMPOSE_FILE="${PROJECT_DIR}/docker-compose.codespaces.yml"
readonly WINGS_COMPOSE_FILE="${PROJECT_DIR}/docker-compose.wings.codespaces.yml"
readonly PANEL_ENV_FILE="${PROJECT_DIR}/.codespaces/.env"
readonly PHP_HELPER="${PROJECT_DIR}/scripts/provision-codespaces-node.php"
readonly UI_LIBRARY="${PROJECT_DIR}/scripts/lib/astra-ui.sh"

[[ -f "${UI_LIBRARY}" ]] || { printf 'Biblioteca visual do Astra Panel não encontrada.\n' >&2; exit 1; }
# shellcheck disable=SC1090
source "${UI_LIBRARY}"
export ASTRA_LOG_FILE="${PROJECT_DIR}/.codespaces/logs/node-install.log"

declare -a COMPOSE DOCKER

info() {
  astra_info "$1"
}

warning() {
  astra_warning "$1"
}

fail() {
  astra_fail "$1"
}

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    fail "Esta etapa precisa de acesso administrativo e o comando sudo não está disponível."
  fi
}

prepare_runtime_directory() {
  # Game containers are created by the host Docker daemon. Therefore this path
  # must be identical inside Wings and on the Codespace host.
  [[ "${WINGS_RUN_DIR}" == "/run/wings" ]] \
    || fail "WINGS_RUN_DIR deve permanecer em /run/wings no GitHub Codespaces."
  as_root install -d -m 0755 -o 988 -g 988 "${WINGS_RUN_DIR}" "${WINGS_RUN_DIR}/machine-id"
}

select_docker_command() {
  if docker info >/dev/null 2>&1; then
    DOCKER=(docker)
  elif command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
    DOCKER=(sudo -n docker)
  else
    fail "O Docker nao esta em execucao."
  fi

  "${DOCKER[@]}" compose version >/dev/null 2>&1 \
    || fail "O plugin Docker Compose v2 nao foi encontrado."
}

calculate_resources() {
  local available_disk_mb default_disk_mb default_memory_mb total_memory_mb

  total_memory_mb="$(awk '/MemTotal/ { print int($2 / 1024) }' /proc/meminfo)"
  if (( total_memory_mb >= 6144 )); then
    default_memory_mb=$((total_memory_mb - 3072))
  else
    default_memory_mb=$((total_memory_mb / 2))
  fi
  (( default_memory_mb >= 1024 )) || default_memory_mb=1024
  (( default_memory_mb <= 8192 )) || default_memory_mb=8192

  available_disk_mb="$(df -Pm -- "${PROJECT_DIR}" | awk 'NR == 2 { print $4 }')"
  default_disk_mb=$((available_disk_mb - 5120))
  (( default_disk_mb >= 2048 )) || default_disk_mb=2048
  (( default_disk_mb <= 20480 )) || default_disk_mb=20480

  NODE_MEMORY_MB="${WINGS_MEMORY_MB:-${default_memory_mb}}"
  NODE_DISK_MB="${WINGS_DISK_MB:-${default_disk_mb}}"

  if [[ ! "${NODE_MEMORY_MB}" =~ ^[0-9]+$ ]] || (( NODE_MEMORY_MB < 1024 )); then
    fail "WINGS_MEMORY_MB deve ser um numero igual ou maior que 1024."
  fi
  if [[ ! "${NODE_DISK_MB}" =~ ^[0-9]+$ ]] || (( NODE_DISK_MB < 2048 )); then
    fail "WINGS_DISK_MB deve ser um numero igual ou maior que 2048."
  fi
}

wait_for_wings() {
  local attempt

  info "Aguardando o Wings responder localmente..."
  for ((attempt = 1; attempt <= 90; attempt++)); do
    if curl -sS --max-time 3 --output /dev/null "http://127.0.0.1:${WINGS_FORWARD_PORT}/api/system"; then
      return
    fi
    sleep 2
  done

  "${COMPOSE[@]}" logs --tail 150 wings >&2 || true
  fail "O Wings nao respondeu. Os ultimos logs foram exibidos acima."
}

publish_wings_port() {
  local attempt

  printf '\nPorta detectada pelo Codespaces: http://localhost:%s\n' "${WINGS_FORWARD_PORT}"
  command -v gh >/dev/null 2>&1 || return 1
  gh auth status >/dev/null 2>&1 || return 1

  for ((attempt = 1; attempt <= 10; attempt++)); do
    if gh codespace ports visibility "${WINGS_FORWARD_PORT}:public" -c "${CODESPACE_NAME}" >/dev/null 2>&1; then
      return
    fi
    sleep 3
  done

  return 1
}

check_panel_connection() {
  local attempt

  info "Validando a conexao autenticada entre o Panel e o Wings..."
  for ((attempt = 1; attempt <= 30; attempt++)); do
    if "${COMPOSE[@]}" exec -T \
      -e NODE_ACTION=check \
      -e "NODE_ID=${NODE_ID}" \
      panel php /tmp/provision-codespaces-node.php >/dev/null 2>&1; then
      return
    fi
    sleep 3
  done

  return 1
}

command -v curl >/dev/null 2>&1 || fail "O comando curl nao esta instalado."
command -v docker >/dev/null 2>&1 || fail "O comando docker nao esta instalado."
[[ -n "${CODESPACE_NAME:-}" ]] || fail "Este instalador deve ser executado dentro do GitHub Codespaces."
[[ -f "${PANEL_ENV_FILE}" ]] || fail "Instale o Panel primeiro executando bash scripts/install-codespaces.sh."
[[ -f "${PHP_HELPER}" ]] || fail "O helper de criacao do node nao foi encontrado."

select_docker_command
astra_banner
astra_section "Configurando o node Wings"

set -a
# shellcheck disable=SC1090
source "${PANEL_ENV_FILE}"
set +a

calculate_resources

export WINGS_FORWARD_PORT="${WINGS_FORWARD_PORT:-8081}"
export WINGS_SFTP_PORT="${WINGS_SFTP_PORT:-2022}"
export WINGS_STATE_DIR="${PROJECT_DIR}/.codespaces/wings"
export WINGS_CONFIG_DIR="${WINGS_STATE_DIR}/etc"
export WINGS_RUN_DIR="/run/wings"
export NODE_NAME="${WINGS_NODE_NAME:-Codespaces Node}"
export NODE_FQDN="${CODESPACE_NAME}-${WINGS_FORWARD_PORT}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
export NODE_MEMORY_MB NODE_DISK_MB
export ALLOCATION_IP="${WINGS_ALLOCATION_IP:-0.0.0.0}"
export ALLOCATION_PORTS="${WINGS_ALLOCATION_PORTS:-25565-25575}"

if [[ ! "${WINGS_FORWARD_PORT}" =~ ^[0-9]+$ ]] || (( WINGS_FORWARD_PORT < 1024 || WINGS_FORWARD_PORT > 65535 )); then
  fail "WINGS_FORWARD_PORT deve ser uma porta entre 1024 e 65535."
fi
if [[ ! "${WINGS_SFTP_PORT}" =~ ^[0-9]+$ ]] || (( WINGS_SFTP_PORT < 1024 || WINGS_SFTP_PORT > 65535 )); then
  fail "WINGS_SFTP_PORT deve ser uma porta entre 1024 e 65535."
fi

mkdir -p \
  "${WINGS_CONFIG_DIR}" \
  "${WINGS_STATE_DIR}/volumes" \
  "${WINGS_STATE_DIR}/logs" \
  "${WINGS_STATE_DIR}/archives" \
  "${WINGS_STATE_DIR}/backups" \
  "${WINGS_STATE_DIR}/tmp"

prepare_runtime_directory

COMPOSE=(
  "${DOCKER[@]}" compose
  --project-name pterodactyl-codespaces
  --env-file "${PANEL_ENV_FILE}"
  -f "${BASE_COMPOSE_FILE}"
  -f "${WINGS_COMPOSE_FILE}"
)

"${COMPOSE[@]}" ps --status running panel | grep -q panel \
  || fail "O container do Panel nao esta em execucao. Rode bash scripts/install-codespaces.sh primeiro."

astra_run "Enviando o provisionador para o Astra Panel" "${COMPOSE[@]}" cp "${PHP_HELPER}" panel:/tmp/provision-codespaces-node.php

NODE_ID="$("${COMPOSE[@]}" exec -T \
  -e NODE_ACTION=provision \
  -e "NODE_NAME=${NODE_NAME}" \
  -e "NODE_FQDN=${NODE_FQDN}" \
  -e "PANEL_PUBLIC_URL=${APP_URL}" \
  -e "WINGS_STATE_DIR=${WINGS_STATE_DIR}" \
  -e "NODE_MEMORY_MB=${NODE_MEMORY_MB}" \
  -e "NODE_DISK_MB=${NODE_DISK_MB}" \
  -e "ALLOCATION_IP=${ALLOCATION_IP}" \
  -e "ALLOCATION_PORTS=${ALLOCATION_PORTS}" \
  panel php /tmp/provision-codespaces-node.php | tr -d '[:space:]')"
export NODE_ID
[[ "${NODE_ID}" =~ ^[0-9]+$ ]] || fail "O Panel nao retornou um ID de node valido."

umask 077
rm -f "${WINGS_CONFIG_DIR}/config.yml.new"
"${COMPOSE[@]}" cp panel:/tmp/astra-panel-codespaces-wings.yml "${WINGS_CONFIG_DIR}/config.yml.new"
mv -f "${WINGS_CONFIG_DIR}/config.yml.new" "${WINGS_CONFIG_DIR}/config.yml"
chmod 600 "${WINGS_CONFIG_DIR}/config.yml"

astra_run "Iniciando o Wings oficial v1.12.2" "${COMPOSE[@]}" up --detach --force-recreate wings
wait_for_wings

PORT_IS_PUBLIC=false
if publish_wings_port; then
  PORT_IS_PUBLIC=true
  info "A porta ${WINGS_FORWARD_PORT} foi configurada como publica para o Panel acessar o node."
else
  warning "Nao consegui tornar a porta ${WINGS_FORWARD_PORT} publica automaticamente. Na aba PORTAS, altere a visibilidade dela para Publica."
fi

NODE_IS_CONNECTED=false
if [[ "${PORT_IS_PUBLIC}" == "true" ]] && check_panel_connection; then
  NODE_IS_CONNECTED=true
fi

astra_section "Node concluído"
astra_success "Wings está pronto no Astra Panel"
printf 'Node ID:       %s\n' "${NODE_ID}"
printf 'Wings URL:     https://%s\n' "${NODE_FQDN}"
printf 'Memoria:       %s MB\n' "${NODE_MEMORY_MB}"
printf 'Disco:         %s MB\n' "${NODE_DISK_MB}"
printf 'Allocations:   %s (%s)\n' "${ALLOCATION_IP}" "${ALLOCATION_PORTS}"

if [[ "${NODE_IS_CONNECTED}" == "true" ]]; then
  printf 'Status:        conectado ao Panel\n'
else
  printf 'Status:        aguardando porta %s ficar publica\n' "${WINGS_FORWARD_PORT}"
  printf '\nDepois de tornar a porta publica, execute este script novamente.\n'
fi

printf '\nPara acompanhar os logs: %s\n' \
  "docker logs astra-panel-wings -f"
