#!/usr/bin/env bash

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  ASTRA_CYAN='\033[38;5;45m'; ASTRA_PURPLE='\033[38;5;141m'; ASTRA_GREEN='\033[38;5;82m'
  ASTRA_YELLOW='\033[38;5;220m'; ASTRA_RED='\033[38;5;203m'; ASTRA_DIM='\033[2m'
  ASTRA_BOLD='\033[1m'; ASTRA_RESET='\033[0m'
else
  ASTRA_CYAN=''; ASTRA_PURPLE=''; ASTRA_GREEN=''; ASTRA_YELLOW=''
  ASTRA_RED=''; ASTRA_DIM=''; ASTRA_BOLD=''; ASTRA_RESET=''
fi

astra_banner() {
  printf '\n%b' "${ASTRA_PURPLE}${ASTRA_BOLD}"
  printf '    ___        __             ____                  __\n'
  printf '   /   | _____/ /________ _  / __ \\____ _____  ___ / /\n'
  printf '  / /| |/ ___/ __/ ___/  / / /_/ / __ `/ __ \\/ _ \\/ / \n'
  printf ' / ___ (__  ) /_/ /  / /|  / ____/ /_/ / / / /  __/ /  \n'
  printf '/_/  |_/____/\\__/_/  /_/ |_/_/    \\__,_/_/ /_/\\___/_/   \n'
  printf '%b\n' "${ASTRA_RESET}${ASTRA_DIM}  Painel de servidores para GitHub Codespaces${ASTRA_RESET}"
}
astra_section() { printf '\n%b◆ %s%b\n' "${ASTRA_PURPLE}${ASTRA_BOLD}" "$1" "${ASTRA_RESET}"; }
astra_info() { printf '%bℹ%b  %s\n' "${ASTRA_CYAN}" "${ASTRA_RESET}" "$1"; }
astra_success() { printf '%b✓%b  %s\n' "${ASTRA_GREEN}" "${ASTRA_RESET}" "$1"; }
astra_warning() { printf '%b!%b  %s\n' "${ASTRA_YELLOW}" "${ASTRA_RESET}" "$1" >&2; }
astra_fail() { printf '\n%b✗ ERRO:%b %s\n' "${ASTRA_RED}${ASTRA_BOLD}" "${ASTRA_RESET}" "$1" >&2; exit 1; }

astra_run() {
  local label="$1" log_file="${ASTRA_LOG_FILE:-/tmp/astra-panel.log}"
  shift
  mkdir -p "$(dirname "${log_file}")"
  if [[ "${ASTRA_VERBOSE:-0}" == "1" || ! -t 1 ]]; then
    astra_info "${label}"
    "$@" 2>&1 | tee -a "${log_file}"
    astra_success "${label}"
    return
  fi
  "$@" >>"${log_file}" 2>&1 &
  local pid=$! frame=0
  local -a frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  while kill -0 "${pid}" 2>/dev/null; do
    printf '\r%b%s%b  %s' "${ASTRA_CYAN}" "${frames[frame]}" "${ASTRA_RESET}" "${label}"
    frame=$(((frame + 1) % ${#frames[@]}))
    sleep 0.1
  done
  if wait "${pid}"; then
    printf '\r\033[2K'; astra_success "${label}"
  else
    local status=$?
    printf '\r\033[2K'; astra_warning "${label} falhou. Últimas linhas de ${log_file}:"
    tail -n 80 "${log_file}" >&2 || true
    return "${status}"
  fi
}
