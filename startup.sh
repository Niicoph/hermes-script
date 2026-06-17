#!/bin/bash
# =============================================================================
#   sudo bash startup.sh
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "  Patagonian — Hermes + Teams Gateway"
echo "  $(date)"
echo "=========================================="

# --- 1. Verificar root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Ejecutar como root (sudo bash startup.sh)"
    exit 1
fi

# --- 2. Instalar Docker ---
echo ""
echo "[1/2] Instalando Docker..."
if ! command -v docker &>/dev/null; then
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg \
        -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo "  Docker instalado."
else
    echo "  Docker ya instalado."
fi

# --- 3. Construir imagen Docker con Teams SDK ---
echo ""
echo "[2/2] Construyendo imagen hermes-agent-teams:latest..."
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
echo "      -v /opt/data/hermes-home:/opt/data \\"
echo "      -e HERMES_UID=1000 \\"
echo "      -e HERMES_GID=1000 \\"
echo "      hermes-agent-teams:latest \\"
echo "      gateway run"
echo ""
