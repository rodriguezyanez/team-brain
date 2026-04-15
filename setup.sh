#!/usr/bin/env bash
# =============================================================
# setup.sh — Instalador unificado de Team Brain (Linux / macOS)
#
# Uso:
#   chmod +x setup.sh && ./setup.sh
#
# Orquesta todo el setup de primer uso en un solo comando:
#   1. Verifica prerequisitos
#   2. Levanta Neo4j
#   3. Inicializa la base de datos
#   4. Carga la arquitectura de referencia KLAP BYSF
#   5. Registra el MCP en Claude Code
#   6. Instala CLAUDE.md en el perfil del usuario
# =============================================================

set -euo pipefail

# -- Colores ---------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# -- Helpers ---------------------------------------------------
ok()   { echo -e "  ${GREEN}[OK]${NC}   $1"; }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "  ${RED}[ERROR]${NC} $1"; }
info() { echo -e "  ${GRAY}[INFO]${NC} $1"; }
skip() { echo -e "  ${GRAY}[SKIP]${NC} $1"; }
step() { echo -e "\n${CYAN}-- $1${NC}"; echo; }

# -─ Banner ────────────────────────────────────────────────────
echo
echo -e "${CYAN}=====================================================${NC}"
echo -e "${CYAN}  Team Brain -- Instalador unificado${NC}"
echo -e "${CYAN}  KLAP BYSF Knowledge Graph Setup${NC}"
echo -e "${CYAN}=====================================================${NC}"
echo

# =============================================================
# PASO 0: Detectar password desde docker-compose.yml
# =============================================================
NEO4J_PASS="team-brain-2025"

if [ -f "docker-compose.yml" ]; then
    DETECTED=$(grep "NEO4J_AUTH" docker-compose.yml | sed 's/.*neo4j\///' | tr -d ' \r\n"' 2>/dev/null || true)
    if [ -n "$DETECTED" ]; then
        NEO4J_PASS="$DETECTED"
    fi
fi
info "Password Neo4j detectada desde docker-compose.yml: $NEO4J_PASS"

# =============================================================
# PASO 1: Verificar prerequisitos
# =============================================================
step "PASO 1: Verificando prerequisitos ─────────────────────"

ERRORS=0
CLAUDE_AVAILABLE=false

# -- Docker --
if docker info >/dev/null 2>&1; then
    ok "Docker corriendo"
else
    err "Docker no está corriendo o no está instalado."
    echo "     Inicia Docker Desktop o instala Docker Engine."
    ERRORS=$((ERRORS + 1))
fi

# -- Docker Compose --
if docker compose version >/dev/null 2>&1; then
    ok "docker compose disponible"
else
    err "docker compose no disponible. Actualiza Docker."
    ERRORS=$((ERRORS + 1))
fi

# -- Node.js >= 18 --
if command -v node >/dev/null 2>&1; then
    NODE_MAJOR=$(node --version | sed 's/v\([0-9]*\).*/\1/')
    if [ "$NODE_MAJOR" -ge 18 ]; then
        ok "Node.js $NODE_MAJOR instalado"
    else
        warn "Node.js $NODE_MAJOR detectado. Se recomienda Node.js 18+."
    fi
else
    err "Node.js no encontrado. Instala Node.js 18+ desde https://nodejs.org"
    ERRORS=$((ERRORS + 1))
fi

# -- curl --
if command -v curl >/dev/null 2>&1; then
    ok "curl disponible"
else
    err "curl no encontrado. Instala curl para continuar."
    ERRORS=$((ERRORS + 1))
fi

# -- Claude Code --
if command -v claude >/dev/null 2>&1; then
    ok "Claude Code instalado"
    CLAUDE_AVAILABLE=true
else
    warn "Claude Code (claude CLI) no encontrado."
    echo "       El MCP no se podrá registrar automáticamente."
    echo "       Instala con: npm install -g @anthropic-ai/claude-code"
fi

if [ "$ERRORS" -gt 0 ]; then
    echo
    err "Se encontraron $ERRORS error(es) crítico(s). Corrígelos y vuelve a ejecutar."
    echo
    exit 1
fi

echo
ok "Todos los prerequisitos OK."

# =============================================================
# PASO 2: Levantar Neo4j
# =============================================================
step "PASO 2: Levantando Neo4j ────────────────────────────────"

if docker compose up -d; then
    ok "Contenedor Neo4j iniciado."
else
    err "No se pudo levantar Neo4j. Verifica docker-compose.yml."
    exit 1
fi

# =============================================================
# PASO 3: Inicializar base de datos
# =============================================================
step "PASO 3: Inicializando base de datos ──────────────────────"

if [ -f "./linux/init-brain.sh" ]; then
    chmod +x ./linux/init-brain.sh
    if ./linux/init-brain.sh; then
        : # ok ya lo imprime init-brain.sh
    else
        err "linux/init-brain.sh falló."
        exit 1
    fi
else
    err "linux/init-brain.sh no encontrado."
    exit 1
fi

# =============================================================
# PASO 4: Cargar arquitectura de referencia KLAP BYSF
# =============================================================
step "PASO 4: Cargando arquitectura KLAP BYSF ─────────────────"

if [ -f "./linux/enrich-brain.sh" ]; then
    chmod +x ./linux/enrich-brain.sh
    if ./linux/enrich-brain.sh; then
        ok "Arquitectura de referencia cargada en Neo4j."
    else
        warn "enrich-brain.sh terminó con errores. Continuando..."
    fi
else
    skip "linux/enrich-brain.sh no encontrado. Saltando enriquecimiento."
fi

# =============================================================
# PASO 5: Registrar MCP en Claude Code
# =============================================================
step "PASO 5: Registrando MCP en Claude Code ───────────────────"

if [ "$CLAUDE_AVAILABLE" = true ]; then
    MCP_CONFIG="{\"command\":\"npx\",\"args\":[\"-y\",\"@knowall-ai/mcp-neo4j-agent-memory\"],\"env\":{\"NEO4J_URI\":\"bolt://localhost:7687\",\"NEO4J_USERNAME\":\"neo4j\",\"NEO4J_PASSWORD\":\"${NEO4J_PASS}\",\"NEO4J_DATABASE\":\"neo4j\"}}"

    if claude mcp add-json "team-brain" "$MCP_CONFIG" --scope user 2>/dev/null; then
        ok "MCP team-brain registrado con scope user."
    else
        info "MCP ya registrado o error en registro. Verifica con: claude mcp list"
    fi
else
    skip "Claude Code no disponible. Registra el MCP manualmente:"
    echo "       claude mcp add-json \"team-brain\" '{\"command\":\"npx\",\"args\":[\"-y\",\"@knowall-ai/mcp-neo4j-agent-memory\"],\"env\":{\"NEO4J_URI\":\"bolt://localhost:7687\",\"NEO4J_USERNAME\":\"neo4j\",\"NEO4J_PASSWORD\":\"${NEO4J_PASS}\",\"NEO4J_DATABASE\":\"neo4j\"}}' --scope user"
fi

# =============================================================
# PASO 5b: Registrar Context7 MCP (opcional — docs en tiempo real)
# =============================================================
step "PASO 5b: Registrando Context7 MCP (opcional) ────────────"

if [ "$CLAUDE_AVAILABLE" = true ]; then
    if claude mcp add-json "context7" '{"command":"npx","args":["-y","@upstash/context7-mcp"]}' --scope user 2>/dev/null; then
        ok "Context7 registrado. Agrega 'use context7' a tus prompts para docs en tiempo real."
    else
        info "Context7 ya registrado o no disponible. Continua..."
    fi
else
    skip "Claude Code no disponible. Registra Context7 con: ./install-context7.sh"
fi

# =============================================================
# PASO 5c: Registrar Sequential Thinking MCP
# =============================================================
step "PASO 5c: Registrando Sequential Thinking MCP ──────────"

if [ "$CLAUDE_AVAILABLE" = true ]; then
    if claude mcp add-json "sequential-thinking" '{"command":"npx","args":["-y","@modelcontextprotocol/server-sequential-thinking"]}' --scope user 2>/dev/null; then
        ok "Sequential Thinking MCP registrado."
    else
        info "Sequential Thinking ya registrado o no disponible. Continua..."
    fi
else
    skip "Claude Code no disponible. Registra manualmente:"
    echo "       claude mcp add-json \"sequential-thinking\" '{\"command\":\"npx\",\"args\":[\"-y\",\"@modelcontextprotocol/server-sequential-thinking\"]}' --scope user"
fi

# =============================================================
# PASO 5d: Instalar plugins de Claude Code
# (superpowers, context-mode, context7-plugin)
# Se configuran via settings.json — no via mcp add-json
# =============================================================
step "PASO 5d: Instalando plugins Claude Code ─────────────────"

SETTINGS_FILE="$HOME/.claude/settings.json"

node -e "
const fs = require('fs');
const settingsPath = process.argv[1];
let settings = {};
if (fs.existsSync(settingsPath)) {
  try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch(e) {}
}
if (!settings.enabledPlugins) settings.enabledPlugins = {};
settings.enabledPlugins['superpowers@claude-plugins-official'] = true;
settings.enabledPlugins['context-mode@context-mode'] = true;
settings.enabledPlugins['context7@claude-plugins-official'] = true;
settings.enabledPlugins['code-simplifier@claude-plugins-official'] = true;
settings.enabledPlugins['code-review@claude-plugins-official'] = true;
settings.enabledPlugins['pr-review-toolkit@claude-plugins-official'] = true;
settings.enabledPlugins['commit-commands@claude-plugins-official'] = true;
settings.enabledPlugins['feature-dev@claude-plugins-official'] = true;
settings.enabledPlugins['claude-md-management@claude-plugins-official'] = true;
if (!settings.extraKnownMarketplaces) settings.extraKnownMarketplaces = {};
settings.extraKnownMarketplaces['context-mode'] = {
  source: { source: 'github', repo: 'mksglu/context-mode' }
};
fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
console.log('OK');
" "$SETTINGS_FILE" 2>/dev/null && ok "Plugins registrados: superpowers, context-mode, context7, code-simplifier, code-review, pr-review-toolkit, commit-commands, feature-dev, claude-md-management" || warn "No se pudieron registrar los plugins. Instálalos manualmente en Claude Code."

info "Nota: Atlassian Rovo requiere autenticacion OAuth manual en claude.ai"
info "      Conecta tu cuenta Atlassian en: https://claude.ai/settings/integrations"

# =============================================================
# PASO 6: Instalar skill files locales en Claude Code
# =============================================================
step "PASO 6: Instalando skills locales ──────────────────────"

if [ -f "./linux/install-skills.sh" ]; then
    chmod +x ./linux/install-skills.sh
    ./linux/install-skills.sh || warn "install-skills.sh terminó con errores. Continuando..."
else
    skip "linux/install-skills.sh no encontrado. Saltando skills locales."
fi

# =============================================================
# PASO 7: Instalar CLAUDE.md en el perfil del usuario
# =============================================================
step "PASO 7: Instalando CLAUDE.md ────────────────────────────"

CLAUDE_DIR="$HOME/.claude"
DEST_PATH="$CLAUDE_DIR/CLAUDE.md"

if [ -f "CLAUDE.md" ]; then
    mkdir -p "$CLAUDE_DIR"

    if [ -f "$DEST_PATH" ]; then
        info "Ya existe $DEST_PATH"
        cp "$DEST_PATH" "${DEST_PATH}.bak"
        info "Backup creado: ${DEST_PATH}.bak"
    fi

    if cp "CLAUDE.md" "$DEST_PATH"; then
        ok "CLAUDE.md instalado en $DEST_PATH"
    else
        warn "No se pudo copiar CLAUDE.md. Cópialo manualmente: cp CLAUDE.md ~/.claude/CLAUDE.md"
    fi
else
    skip "CLAUDE.md no encontrado en el directorio actual."
fi

# =============================================================
# PASO 8: Guardian Angel hook pre-commit (opcional)
# =============================================================
step "PASO 8: Guardian Angel hook pre-commit (opcional) ──────"

echo "  Para instalar el hook en tu proyecto:"
echo "    ./linux/install-hooks.sh /ruta/a/tu/proyecto"
echo ""
echo "  El hook revisará cada commit Java/Kotlin contra las reglas del equipo."
echo "  Bypass urgente: git commit --no-verify"
echo ""

# =============================================================
# RESUMEN FINAL
# =============================================================
echo
echo -e "${GREEN}=====================================================${NC}"
echo -e "${GREEN}  Team Brain instalado correctamente!${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo
echo "  Neo4j Browser : http://localhost:7474"
echo "  Usuario       : neo4j"
echo "  Password      : $NEO4J_PASS"
echo "  Bolt URI      : bolt://localhost:7687"
echo
echo "  MCPs registrados:"
echo "    team-brain, context7, sequential-thinking"
echo "  Plugins registrados:"
echo "    superpowers, context-mode, context7"
echo "    code-simplifier, code-review, pr-review-toolkit"
echo "    commit-commands, feature-dev, claude-md-management"
echo "  Atlassian Rovo (OAuth manual): https://claude.ai/settings/integrations"
echo
echo "  Verificar conexión MCP:"
echo "    claude mcp list"
echo
echo "  Verificar grafo en Neo4j Browser:"
echo "    MATCH (n:Entity) RETURN n"
echo
echo -e "  ${CYAN}Próximos pasos:${NC}"
echo "    1. Abre Claude Code en tu proyecto"
echo "    2. Indica el microservicio en el que vas a trabajar"
echo
echo "  Operación diaria:"
echo "    docker compose up -d         <- levantar Neo4j"
echo "    docker compose down          <- detener Neo4j"
echo "    docker compose ps            <- ver estado"
echo "    ./linux/brain-sync.sh        <- sincronizar memoria local pendiente"
echo -e "${GREEN}=====================================================${NC}"
echo
