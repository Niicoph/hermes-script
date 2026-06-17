#!/bin/bash
# =============================================================================
# startup.sh — Patagonian Hermes + Teams Gateway
#
# Uso:
#   curl -O https://raw.githubusercontent.com/Niicoph/hermes-script/main/startup.sh
#   curl -O https://raw.githubusercontent.com/Niicoph/hermes-script/main/Dockerfile.hermes-teams
#   sudo bash startup.sh
#
# Requiere: Ubuntu 24.04+, conectividad a internet
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
export DEBIAN_FRONTEND=noninteractive

echo "=========================================="
echo "  Patagonian — Hermes + Teams Gateway"
echo "  $(date)"
echo "=========================================="

# --- 1. Verificar root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Ejecutar como root (sudo bash startup.sh)"
    exit 1
fi

# --- 2. Obtener codename de Ubuntu ---
. /etc/os-release
UBUNTU_CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
echo "  OS: ${ID} ${UBUNTU_CODENAME} (${VERSION_ID})"

# --- 3. Instalar Docker ---
echo ""
echo "[1/3] Instalando Docker..."
if ! command -v docker &>/dev/null; then
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    rm -f /etc/apt/sources.list.d/docker.list
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo "  Docker instalado."
else
    echo "  Docker ya instalado."
fi

# --- 5. Construir imagen Docker con Teams SDK ---
echo ""
echo "[3/3] Construyendo imagen hermes-agent-teams:latest..."
docker build -t hermes-agent-teams:latest \
    -f "${REPO_DIR}/Dockerfile.hermes-teams" "${REPO_DIR}"
echo "  Imagen construida."
echo ""
echo "=========================================="
echo "  Instalacion completada"
echo "=========================================="
echo ""
echo "  Para iniciar el gateway:"
echo ""
echo "    docker run -d \\"
echo "      --name hermes-gateway \\"
echo "      --restart unless-stopped \\"
echo "      --network host \\"
echo "      -v ~/.hermes:/opt/data \\"
echo "      -e HERMES_UID=$(id -u) \\"
echo "      -e HERMES_GID=$(id -g) \\"
echo "      hermes-agent-teams:latest \\"
echo "      gateway run"
echo ""
