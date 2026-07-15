#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PROJECT_DIR
readonly ENV_FILE="${PROJECT_DIR}/.codespaces/.env"
readonly UI_LIBRARY="${PROJECT_DIR}/scripts/lib/astra-ui.sh"

[[ -f "${UI_LIBRARY}" ]] || { printf 'Biblioteca visual do Astra Panel nao encontrada.\n' >&2; exit 1; }
# shellcheck disable=SC1090
source "${UI_LIBRARY}"
export ASTRA_LOG_FILE="${PROJECT_DIR}/.codespaces/logs/ports.log"

[[ -n "${CODESPACE_NAME:-}" ]] || astra_fail "Este reparo deve ser executado dentro do GitHub Codespaces."
[[ -f "${ENV_FILE}" ]] || astra_fail "A instalacao do Astra Panel nao foi encontrada."
command -v curl >/dev/null 2>&1 || astra_fail "O comando curl nao esta instalado."
command -v gh >/dev/null 2>&1 || astra_fail "O GitHub CLI nao esta instalado."
gh auth status >/dev/null 2>&1 || astra_fail "Autentique o GitHub CLI executando: gh auth login"

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

PANEL_PORT="${PTERO_PORT:-8080}"
WINGS_PORT="${WINGS_FORWARD_PORT:-8081}"
PORT_DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
PANEL_ORIGIN="${APP_URL%/}"
WINGS_ORIGIN="https://${CODESPACE_NAME}-${WINGS_PORT}.${PORT_DOMAIN}"

publish_port() {
  local port="$1" attempt

  for ((attempt = 1; attempt <= 10; attempt++)); do
    if gh codespace ports visibility "${port}:public" -c "${CODESPACE_NAME}" >/dev/null 2>&1; then
      return
    fi
    sleep 2
  done

  return 1
}

validate_cors() {
  local attempt headers

  for ((attempt = 1; attempt <= 20; attempt++)); do
    headers="$(curl -sS --max-time 15 --dump-header - --output /dev/null \
      --request OPTIONS \
      --header "Origin: ${PANEL_ORIGIN}" \
      --header 'Access-Control-Request-Method: POST' \
      --header 'Access-Control-Request-Headers: authorization,content-type' \
      "${WINGS_ORIGIN}/api/system" 2>/dev/null || true)"

    if printf '%s' "${headers}" | tr -d '\r' | grep -Fqi "access-control-allow-origin: ${PANEL_ORIGIN}"; then
      return
    fi
    sleep 2
  done

  return 1
}

astra_banner
astra_section "Reparando acesso pelas portas"
astra_run "Publicando a porta ${PANEL_PORT} do Astra Panel" publish_port "${PANEL_PORT}"
astra_run "Publicando a porta ${WINGS_PORT} do Wings" publish_port "${WINGS_PORT}"

if ! curl -sS --max-time 5 --output /dev/null "http://127.0.0.1:${WINGS_PORT}/api/system"; then
  astra_fail "A porta ${WINGS_PORT} esta publica, mas o Wings nao esta respondendo localmente."
fi

astra_run "Validando upload e CORS entre Panel e Wings" validate_cors
astra_success "Portas publicas e CORS funcionando corretamente"
printf 'Panel: %s\n' "${PANEL_ORIGIN}"
printf 'Wings: %s\n' "${WINGS_ORIGIN}"
printf '\nSe o Codespace for reiniciado, execute novamente:\n'
printf 'bash %s/scripts/publish-codespaces-ports.sh\n' "${PROJECT_DIR}"
