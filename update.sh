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

preserve_legacy_wings_override() {
  local compose_file="docker-compose.wings.codespaces.yml" backup_dir backup_file

  if git -C "${ASTRA_DIR}" diff --quiet HEAD -- "${compose_file}"; then
    return
  fi

  backup_dir="${ASTRA_DIR}/.codespaces/backups"
  backup_file="${backup_dir}/local-wings-compose-$(date +%Y%m%d-%H%M%S).patch"
  mkdir -p "${backup_dir}"
  git -C "${ASTRA_DIR}" diff HEAD -- "${compose_file}" > "${backup_file}"
  git -C "${ASTRA_DIR}" restore --staged --worktree -- "${compose_file}"
  printf 'Configuração local antiga preservada em %s\n' "${backup_file}"
}

printf '\nAtualizando os arquivos do Astra Panel em %s...\n' "${ASTRA_DIR}"
preserve_legacy_wings_override
git -C "${ASTRA_DIR}" pull --ff-only origin master
exec bash "${ASTRA_DIR}/scripts/update-codespaces.sh"
