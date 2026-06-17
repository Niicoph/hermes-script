#!/bin/bash

set -euo pipefail

HERMES_HOME="/opt/data/hermes-home"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TZ="America/Argentina/Buenos_Aires"

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
echo "[1/4] Instalando Docker..."
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

# --- 3. Crear estructura de directorios ---
echo ""
echo "[2/4] Creando directorios de datos..."
mkdir -p "${HERMES_HOME}"/{cron,sessions,logs,hooks,memories,skills,skins,plans,workspace,home}
chmod 755 "${HERMES_HOME}"
echo "  Directorios creados en ${HERMES_HOME}"

# --- 4. Construir imagen Docker con Teams SDK ---
echo ""
echo "[3/4] Construyendo imagen hermes-agent-teams:latest..."
docker build -t hermes-agent-teams:latest \
    -f "${REPO_DIR}/Dockerfile.hermes-teams" "${REPO_DIR}"
echo "  Imagen construida."

# --- 5. Configurar credenciales de Teams ---
echo ""
echo "[4/4] Configuracion de Microsoft Teams"
echo "--------------------------------------"
echo "Registra un Bot en https://dev.botframework.com/ antes de continuar."
echo ""

read -rp "  TEAMS_CLIENT_ID: " TEAMS_CLIENT_ID
read -rsp "  TEAMS_CLIENT_SECRET: " TEAMS_CLIENT_SECRET
echo ""
read -rp "  TEAMS_TENANT_ID: " TEAMS_TENANT_ID
echo ""

# Modelo — preguntar solo si no esta definido en el entorno
if [ -z "${OPENCODE_GO_API_KEY:-}" ]; then
    read -rp "  OPENCODE_GO_API_KEY (dejar vacio para configurar despues): " OPENCODE_GO_API_KEY
fi

cat > "${HERMES_HOME}/.env" << ENVEOF
TEAMS_CLIENT_ID=${TEAMS_CLIENT_ID}
TEAMS_CLIENT_SECRET=${TEAMS_CLIENT_SECRET}
TEAMS_TENANT_ID=${TEAMS_TENANT_ID}
TEAMS_ALLOW_ALL_USERS=true
TEAMS_PORT=3978
OPENCODE_GO_API_KEY=${OPENCODE_GO_API_KEY:-}
HERMES_UID=1000
HERMES_GID=1000
TZ=${TZ}
ENVEOF
chmod 600 "${HERMES_HOME}/.env"
echo "  .env creado en ${HERMES_HOME}/.env"

# --- 6. Iniciar gateway ---
echo ""
echo "Iniciando gateway..."

docker rm -f hermes-gateway 2>/dev/null || true

docker run -d \
    --name hermes-gateway \
    --restart unless-stopped \
    --network host \
    -v "${HERMES_HOME}:/opt/data" \
    -e HERMES_UID=1000 \
    -e HERMES_GID=1000 \
    hermes-agent-teams:latest \
    gateway run

echo "  Esperando que el gateway responda..."
for i in $(seq 1 15); do
    if curl -sf http://localhost:3978/health >/dev/null 2>&1; then
        echo "  Gateway listo en puerto 3978"
        break
    fi
``` (1/2)
