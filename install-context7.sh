#!/usr/bin/env bash
# =============================================================
# install-context7.sh — Registra Context7 MCP en Claude Code
# Context7 provee documentacion en tiempo real de las librerias
# del stack: Spring Boot 3.5.11, Kafka, Resilience4j, WebClient
# =============================================================
set -euo pipefail

# --- Colores ANSI ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Funciones de log ---
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC}  $*"; }

echo ""
info "=== Instalando Context7 MCP en Claude Code ==="
echo ""

# --- 1. Verificar claude CLI ---
if ! command -v claude &> /dev/null; then
    err "Claude CLI no encontrado. Instala Claude Code primero."
    err "  https://claude.ai/code"
    exit 1
fi
ok "Claude CLI encontrado: $(command -v claude)"

# --- 2. Verificar npx ---
if ! command -v npx &> /dev/null; then
    err "npx no encontrado. Instala Node.js primero."
    err "  https://nodejs.org"
    exit 1
fi
ok "npx encontrado: $(command -v npx)"

echo ""
info "Registrando Context7 MCP (scope: user)..."
echo ""

# --- 3. Registrar el MCP ---
if claude mcp add-json "context7" '{"command":"npx","args":["-y","@upstash/context7-mcp"]}' --scope user; then
    ok "Context7 MCP registrado correctamente."
else
    EXIT_CODE=$?
    warn "El comando retorno codigo $EXIT_CODE."
    warn "Si context7 ya estaba registrado, puede ignorarse este error."
fi

echo ""

# --- 4. Verificar con mcp list ---
info "MCPs registrados actualmente:"
echo "-----------------------------------------------"
claude mcp list
echo "-----------------------------------------------"

echo ""
ok "=== Instalacion completada ==="
echo ""
info "Como usar Context7 en Claude Code:"
echo ""
echo "  Agrega 'use context7' a tus prompts para obtener"
echo "  docs de la version exacta de las librerias del stack."
echo ""
echo -e "  ${YELLOW}Ejemplo:${NC}"
echo -e "  ${YELLOW}'use context7, como configuro Resilience4j 2.2.0${NC}"
echo -e "  ${YELLOW} con Spring Boot 3.5.11?'${NC}"
echo ""
echo -e "  ${YELLOW}Otros ejemplos:${NC}"
echo -e "  ${YELLOW}- 'use context7, como uso WebClient con retry en Spring Boot 3.5.11?'${NC}"
echo -e "  ${YELLOW}- 'use context7, configuracion de Kafka consumer con Spring 3.5.11'${NC}"
echo -e "  ${YELLOW}- 'use context7, anotaciones de Resilience4j para circuit breaker'${NC}"
echo ""
