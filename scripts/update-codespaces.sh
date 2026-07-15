#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PROJECT_DIR
readonly ENV_FILE="${PROJECT_DIR}/.codespaces/.env"
readonly BASE_COMPOSE_FILE="${PROJECT_DIR}/docker-compose.codespaces.yml"
readonly WINGS_COMPOSE_FILE="${PROJECT_DIR}/docker-compose.wings.codespaces.yml"
readonly UI_LIBRARY="${PROJECT_DIR}/scripts/lib/astra-ui.sh"
readonly LOCK_DIR="${PROJECT_DIR}/.codespaces/update.lock"

[[ -f "${UI_LIBRARY}" ]] || { printf 'Biblioteca visual do Astra Panel não encontrada.\n' >&2; exit 1; }
# shellcheck disable=SC1090
source "${UI_LIBRARY}"
export ASTRA_LOG_FILE="${PROJECT_DIR}/.codespaces/logs/update.log"

declare APP_URL DB_PASSWORD PTERO_PORT
declare -a COMPOSE DOCKER

cleanup() { rmdir "${LOCK_DIR}" >/dev/null 2>&1 || true; }

select_docker_command() {
  if docker info >/dev/null 2>&1; then
    DOCKER=(docker)
  elif command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
    DOCKER=(sudo -n docker)
  else
    astra_fail "O Docker não está em execução."
  fi
  "${DOCKER[@]}" compose version >/dev/null 2>&1 || astra_fail "Docker Compose v2 não foi encontrado."
}

require_clean_repository() {
  git -C "${PROJECT_DIR}" diff --quiet && git -C "${PROJECT_DIR}" diff --cached --quiet \
    || astra_fail "Há alterações locais no projeto. Faça commit ou guarde-as antes de atualizar."
  [[ -z "$(git -C "${PROJECT_DIR}" ls-files --others --exclude-standard)" ]] \
    || astra_fail "Há arquivos novos não versionados no projeto. Remova-os ou faça commit antes de atualizar."
}

wait_for_database() {
  local attempt
  for ((attempt = 1; attempt <= 60; attempt++)); do
    if "${COMPOSE[@]}" exec -T database mariadb-admin \
      --user=pterodactyl --password="${DB_PASSWORD}" ping --silent >/dev/null 2>&1; then
      return
    fi
    sleep 2
  done
  astra_fail "O banco de dados não ficou pronto para o backup."
}

backup_database() {
  local backup_file="$1"
  "${COMPOSE[@]}" exec -T database mariadb-dump \
    --single-transaction --quick --skip-lock-tables \
    --user=pterodactyl --password="${DB_PASSWORD}" panel | gzip -9 > "${backup_file}"
  [[ -s "${backup_file}" ]]
}

wait_for_panel() {
  local attempt
  for ((attempt = 1; attempt <= 150; attempt++)); do
    if curl -fsS --max-time 5 "http://127.0.0.1:${PTERO_PORT}/" >/dev/null 2>&1; then
      return
    fi
    sleep 2
  done
  "${COMPOSE[@]}" logs --tail 120 panel >&2 || true
  astra_fail "O Astra Panel não respondeu depois da atualização. O backup está preservado."
}

command -v git >/dev/null 2>&1 || astra_fail "Git não está instalado."
command -v curl >/dev/null 2>&1 || astra_fail "curl não está instalado."
command -v gzip >/dev/null 2>&1 || astra_fail "gzip não está instalado."
[[ -f "${ENV_FILE}" ]] || astra_fail "Instale o Astra Panel antes de executar o atualizador."
[[ -f "${BASE_COMPOSE_FILE}" ]] || astra_fail "Compose do Astra Panel não encontrado."
mkdir "${LOCK_DIR}" 2>/dev/null || astra_fail "Outra atualização parece estar em andamento."
trap cleanup EXIT INT TERM

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

select_docker_command
COMPOSE=("${DOCKER[@]}" compose --project-name pterodactyl-codespaces --env-file "${ENV_FILE}" -f "${BASE_COMPOSE_FILE}")

astra_banner
astra_section "Verificações de segurança"
require_clean_repository
CURRENT_COMMIT="$(git -C "${PROJECT_DIR}" rev-parse --short HEAD)"
astra_success "Repositório limpo — versão ${CURRENT_COMMIT}"

astra_section "Backup"
mkdir -p "${PROJECT_DIR}/.codespaces/backups" "${PROJECT_DIR}/.codespaces/logs"
astra_run "Garantindo que o banco esteja disponível" "${COMPOSE[@]}" up --detach database cache
wait_for_database
BACKUP_FILE="${PROJECT_DIR}/.codespaces/backups/update-$(date +%Y%m%d-%H%M%S).sql.gz"
astra_run "Criando backup do banco de dados" backup_database "${BACKUP_FILE}"
astra_success "Backup salvo em ${BACKUP_FILE}"

astra_section "Atualizando arquivos"
astra_run "Buscando a versão mais recente" git -C "${PROJECT_DIR}" fetch origin master
astra_run "Aplicando a atualização com segurança" git -C "${PROJECT_DIR}" merge --ff-only origin/master

astra_section "Publicando a nova versão"
astra_run "Reconstruindo a interface Astra" "${COMPOSE[@]}" build --pull panel
astra_run "Recriando os serviços" "${COMPOSE[@]}" up --detach
wait_for_panel

if [[ -f "${PROJECT_DIR}/.codespaces/wings/etc/config.yml" && -f "${WINGS_COMPOSE_FILE}" ]]; then
  WINGS_COMPOSE=("${COMPOSE[@]}" -f "${WINGS_COMPOSE_FILE}")
  astra_run "Atualizando o node Wings" "${WINGS_COMPOSE[@]}" up --detach --force-recreate wings
fi

NEW_COMMIT="$(git -C "${PROJECT_DIR}" rev-parse --short HEAD)"
astra_section "Atualização concluída"
astra_success "Astra Panel atualizado de ${CURRENT_COMMIT} para ${NEW_COMMIT}"
printf 'URL: %s\n' "${APP_URL}"
printf 'Backup: %s\n' "${BACKUP_FILE}"
printf 'Log: %s\n' "${ASTRA_LOG_FILE}"
