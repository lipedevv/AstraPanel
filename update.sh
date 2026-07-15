#!/usr/bin/env bash
set -Eeuo pipefail

readonly ASTRA_REPOSITORY="https://github.com/lipedevv/AstraPanel.git"

find_astra_directory() {
  local candidate origin
  local -a candidates=("${ASTRA_DIR:-}" "${PWD}" /workspaces/AstraPanel /workspaces/Pterodactyl)

  for candidate in "${candidates[@]}"; do
    [[ -n "${candidate}" && -d "${candidate}/.git" ]] || continue
    origin="$(git -C "${candidate}" remote get-url origin 2>/dev/null || true)"
    case "${origin}" in
      "${ASTRA_REPOSITORY}"|https://github.com/lipedevv/AstraPanel|git@github.com:lipedevv/AstraPanel.git)
        printf '%s' "${candidate}"
        return
        ;;
    esac
  done

  printf 'ERRO: não encontrei a instalação do Astra Panel. Use ASTRA_DIR=/caminho.\n' >&2
  exit 1
}

command -v git >/dev/null 2>&1 || { printf 'ERRO: Git não está instalado.\n' >&2; exit 1; }
ASTRA_DIR="$(find_astra_directory)"

printf '\nAtualizando os arquivos do Astra Panel em %s...\n' "${ASTRA_DIR}"
git -C "${ASTRA_DIR}" pull --ff-only origin master
exec bash "${ASTRA_DIR}/scripts/update-codespaces.sh"
