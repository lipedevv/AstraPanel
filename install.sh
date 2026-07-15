#!/usr/bin/env bash
set -Eeuo pipefail

readonly PTERODACTYL_REPOSITORY="https://github.com/lipedevv/AstraPanel.git"
readonly PTERODACTYL_BRANCH="master"

if [[ -n "${PTERO_DIR:-}" ]]; then
  INSTALL_DIR="${PTERO_DIR}"
elif [[ -d /workspaces && -w /workspaces ]]; then
  INSTALL_DIR="/workspaces/Pterodactyl"
else
  INSTALL_DIR="${HOME}/Pterodactyl"
fi
readonly INSTALL_DIR

info() {
  printf '\n[Pterodactyl Codespaces] %s\n' "$1"
}

fail() {
  printf '\n[Pterodactyl Codespaces] ERRO: %s\n' "$1" >&2
  exit 1
}

as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    fail "Esta etapa precisa de acesso administrativo e o comando sudo nao esta disponivel."
  fi
}

install_base_dependencies() {
  if command -v git >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
    return
  fi

  command -v apt-get >/dev/null 2>&1 \
    || fail "Este instalador requer Ubuntu ou Debian quando precisa instalar dependencias."
  info "Instalando Git, curl e certificados..."
  as_root apt-get update
  as_root apt-get install -y ca-certificates curl git
}

configure_docker_repository() {
  local docker_arch docker_distribution docker_key docker_suite

  command -v apt-get >/dev/null 2>&1 \
    || fail "Docker ausente e o gerenciador apt nao foi encontrado."
  [[ -r /etc/os-release ]] || fail "Nao foi possivel identificar a distribuicao Linux."

  # shellcheck disable=SC1091
  . /etc/os-release
  case "${ID:-}" in
    ubuntu)
      docker_distribution="ubuntu"
      docker_suite="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
      ;;
    debian)
      docker_distribution="debian"
      docker_suite="${VERSION_CODENAME:-}"
      ;;
    *)
      fail "A instalacao automatica do Docker e suportada apenas no Ubuntu e Debian."
      ;;
  esac
  [[ -n "${docker_suite}" ]] || fail "Nao foi possivel identificar a versao da distribuicao."

  info "Configurando o repositorio oficial do Docker..."
  as_root apt-get update
  as_root apt-get install -y ca-certificates curl
  as_root install -m 0755 -d /etc/apt/keyrings

  docker_key="$(mktemp)"
  curl -fsSL "https://download.docker.com/linux/${docker_distribution}/gpg" -o "${docker_key}"
  as_root install -m 0644 "${docker_key}" /etc/apt/keyrings/docker.asc
  rm -f "${docker_key}"

  docker_arch="$(dpkg --print-architecture)"
  printf '%s\n' \
    'Types: deb' \
    "URIs: https://download.docker.com/linux/${docker_distribution}" \
    "Suites: ${docker_suite}" \
    'Components: stable' \
    "Architectures: ${docker_arch}" \
    'Signed-By: /etc/apt/keyrings/docker.asc' \
    | as_root tee /etc/apt/sources.list.d/docker.sources >/dev/null

  as_root apt-get update
}

start_docker() {
  if docker info >/dev/null 2>&1 \
    || { command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; }; then
    return
  fi

  info "Iniciando o servico Docker..."
  if command -v systemctl >/dev/null 2>&1; then
    as_root systemctl start docker >/dev/null 2>&1 || true
  fi
  if ! docker info >/dev/null 2>&1 && command -v service >/dev/null 2>&1; then
    as_root service docker start >/dev/null 2>&1 || true
  fi

  docker info >/dev/null 2>&1 \
    || { command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; } \
    || fail "Docker foi instalado, mas o daemon nao iniciou. Recrie o Codespace usando a imagem padrao do GitHub."
}

ensure_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    configure_docker_repository
    as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  elif ! docker compose version >/dev/null 2>&1; then
    configure_docker_repository
    as_root apt-get install -y docker-compose-plugin
  fi

  start_docker
}

checkout_panel() {
  local origin_url

  if [[ -d "${INSTALL_DIR}/.git" ]]; then
    info "Instalacao existente encontrada em ${INSTALL_DIR}. Atualizando..."
    origin_url="$(git -C "${INSTALL_DIR}" remote get-url origin 2>/dev/null || true)"
    case "${origin_url}" in
      "${PTERODACTYL_REPOSITORY}"|https://github.com/lipedevv/AstraPanel|git@github.com:lipedevv/AstraPanel.git)
        ;;
      *)
        fail "O diretorio ${INSTALL_DIR} pertence a outro repositorio. Use PTERO_DIR=/outro/caminho."
        ;;
    esac

    if [[ -n "$(git -C "${INSTALL_DIR}" status --porcelain)" ]]; then
      fail "Existem alteracoes locais em ${INSTALL_DIR}. Salve ou descarte essas alteracoes antes de atualizar."
    fi

    git -C "${INSTALL_DIR}" pull --ff-only origin "${PTERODACTYL_BRANCH}"
    return
  fi

  if [[ -e "${INSTALL_DIR}" && -n "$(find "${INSTALL_DIR}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    fail "O diretorio ${INSTALL_DIR} existe e nao esta vazio. Use PTERO_DIR=/outro/caminho."
  fi

  info "Clonando o Pterodactyl Panel em ${INSTALL_DIR}..."
  mkdir -p "$(dirname "${INSTALL_DIR}")"
  git clone --depth 1 --branch "${PTERODACTYL_BRANCH}" "${PTERODACTYL_REPOSITORY}" "${INSTALL_DIR}"
}

printf '\n========================================\n'
printf ' Instalador do Pterodactyl no Codespaces\n'
printf '========================================\n'

install_base_dependencies
ensure_docker
checkout_panel

info "Executando a instalacao completa do painel..."
exec bash "${INSTALL_DIR}/scripts/install-codespaces.sh"
