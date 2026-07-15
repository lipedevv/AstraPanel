#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PROJECT_DIR
readonly COMPOSE_FILE="${PROJECT_DIR}/docker-compose.codespaces.yml"
readonly STATE_DIR="${PROJECT_DIR}/.codespaces"
readonly ENV_FILE="${STATE_DIR}/.env"
readonly ADMIN_MARKER="${STATE_DIR}/admin-created"
readonly CREDENTIALS_FILE="${STATE_DIR}/credentials.txt"

declare APP_URL ADMIN_EMAIL ADMIN_PASSWORD ADMIN_USERNAME PTERO_PORT
declare -a COMPOSE DOCKER

info() {
  printf '\n[Pterodactyl Codespaces] %s\n' "$1"
}

fail() {
  printf '\n[Pterodactyl Codespaces] ERRO: %s\n' "$1" >&2
  exit 1
}

random_hex() {
  local bytes="$1"

  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "${bytes}"
  else
    od -An -N "${bytes}" -tx1 /dev/urandom | tr -d ' \n'
  fi
}

select_docker_command() {
  if docker info >/dev/null 2>&1; then
    DOCKER=(docker)
  elif command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
    DOCKER=(sudo -n docker)
  else
    fail "O Docker nao esta em execucao. Use um Codespace padrao do GitHub ou recrie o container deste repositorio."
  fi

  "${DOCKER[@]}" compose version >/dev/null 2>&1 \
    || fail "O plugin Docker Compose v2 nao foi encontrado."
}

create_environment() {
  local admin_email admin_password admin_username app_url db_password db_root_password ptero_port

  mkdir -p "${STATE_DIR}/database" "${STATE_DIR}/redis" "${STATE_DIR}/panel-var" "${STATE_DIR}/logs"

  if [[ -f "${ENV_FILE}" ]]; then
    return
  fi

  ptero_port="${PTERO_PORT:-8080}"
  admin_email="${PTERO_ADMIN_EMAIL:-admin@example.com}"
  admin_username="${PTERO_ADMIN_USERNAME:-admin}"
  admin_password="${PTERO_ADMIN_PASSWORD:-Ptero!$(random_hex 12)}"

  if [[ ! "${ptero_port}" =~ ^[0-9]+$ ]] || (( ptero_port < 1024 || ptero_port > 65535 )); then
    fail "PTERO_PORT deve ser uma porta entre 1024 e 65535."
  fi
  [[ "${admin_email}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] \
    || fail "PTERO_ADMIN_EMAIL nao e um endereco de e-mail valido."
  [[ "${admin_username}" =~ ^[A-Za-z0-9_.-]{1,32}$ ]] \
    || fail "PTERO_ADMIN_USERNAME deve ter ate 32 caracteres e usar apenas letras, numeros, ponto, hifen ou sublinhado."
  [[ "${admin_password}" =~ ^[A-Za-z0-9._!@%+=:-]{8,128}$ ]] \
    || fail "PTERO_ADMIN_PASSWORD deve ter de 8 a 128 caracteres seguros."

  if [[ -n "${CODESPACE_NAME:-}" ]]; then
    app_url="https://${CODESPACE_NAME}-${ptero_port}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  else
    app_url="http://localhost:${ptero_port}"
  fi

  db_password="$(random_hex 24)"
  db_root_password="$(random_hex 24)"

  umask 077
  {
    printf 'PTERO_PORT=%s\n' "${ptero_port}"
    printf 'APP_URL=%s\n' "${app_url}"
    printf 'APP_TIMEZONE=America/Sao_Paulo\n'
    printf 'DB_PASSWORD=%s\n' "${db_password}"
    printf 'DB_ROOT_PASSWORD=%s\n' "${db_root_password}"
    printf 'ADMIN_EMAIL=%s\n' "${admin_email}"
    printf 'ADMIN_USERNAME=%s\n' "${admin_username}"
    printf 'ADMIN_PASSWORD=%s\n' "${admin_password}"
  } > "${ENV_FILE}"
  chmod 600 "${ENV_FILE}"
}

load_environment() {
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
}

wait_for_panel() {
  local attempt

  info "Aguardando o painel concluir as migrations..."
  for ((attempt = 1; attempt <= 150; attempt++)); do
    if curl -fsS --max-time 5 "http://127.0.0.1:${PTERO_PORT}/" >/dev/null 2>&1; then
      return
    fi
    sleep 2
  done

  "${COMPOSE[@]}" logs --tail 120 panel >&2 || true
  fail "O painel nao respondeu na porta ${PTERO_PORT}. Os ultimos logs foram exibidos acima."
}

create_admin() {
  if [[ -f "${ADMIN_MARKER}" ]]; then
    return
  fi

  info "Criando o primeiro administrador..."
  "${COMPOSE[@]}" exec -T panel php artisan p:user:make \
    --email="${ADMIN_EMAIL}" \
    --username="${ADMIN_USERNAME}" \
    --name-first="Admin" \
    --name-last="Codespaces" \
    --password="${ADMIN_PASSWORD}" \
    --admin=1

  touch "${ADMIN_MARKER}"
  chmod 600 "${ADMIN_MARKER}"
}

write_credentials() {
  umask 077
  {
    printf 'URL: %s\n' "${APP_URL}"
    printf 'E-mail: %s\n' "${ADMIN_EMAIL}"
    printf 'Senha: %s\n' "${ADMIN_PASSWORD}"
  } > "${CREDENTIALS_FILE}"
  chmod 600 "${CREDENTIALS_FILE}"
}

command -v curl >/dev/null 2>&1 || fail "O comando curl nao esta instalado."
command -v docker >/dev/null 2>&1 || fail "O comando docker nao esta instalado."
[[ -f "${COMPOSE_FILE}" ]] || fail "Arquivo docker-compose.codespaces.yml nao encontrado."

select_docker_command
create_environment
load_environment

COMPOSE=("${DOCKER[@]}" compose --project-name pterodactyl-codespaces --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}")

info "Baixando e iniciando o Pterodactyl Panel oficial v1.14.1..."
"${COMPOSE[@]}" up --detach

wait_for_panel
create_admin
write_credentials

printf '\n========================================\n'
printf ' Pterodactyl Panel pronto no Codespaces\n'
printf '========================================\n'
printf 'URL:    %s\n' "${APP_URL}"
printf 'E-mail: %s\n' "${ADMIN_EMAIL}"
printf 'Senha:  %s\n' "${ADMIN_PASSWORD}"
printf '\nAs credenciais tambem estao em %s\n' "${CREDENTIALS_FILE}"
printf '\nNode Wings opcional: bash %s/scripts/install-node-codespaces.sh\n' "${PROJECT_DIR}"
