#!/usr/bin/env bash
# =============================================================
# install-skills.sh — Instala skill files en Claude Code
# Uso: chmod +x install-skills.sh && ./install-skills.sh
# =============================================================
set -euo pipefail

# --- Colores ANSI ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; }
info() { echo -e "${CYAN}[INFO]${NC}  $*"; }

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="${SCRIPT_DIR}/skills"
SKILLS_DEST="${HOME}/.claude/skills"
EXPECTED=11
COUNT=0

FILES=(
    "kafka-config.md"
    "kafka-listener.md"
    "processor.md"
    "repository.md"
    "webclient.md"
    "exceptions.md"
    "testing.md"
    "openapi.md"
    "skill-registry.md"
    "sdd-microservice.md"
    "sdd-checklist.md"
)

echo ""
info "Team Brain — Instalador de Skills para Claude Code"
info "Origen : ${SKILLS_SRC}"
info "Destino: ${SKILLS_DEST}"
echo ""

# -----------------------------------------------------------
# Verificar carpeta de origen
# -----------------------------------------------------------
if [[ ! -d "${SKILLS_SRC}" ]]; then
    err "No se encontro la carpeta skills/ en el directorio del script."
    err "Ejecuta este script desde la raiz del proyecto team-brain."
    exit 1
fi
ok "Carpeta skills/ encontrada."

# -----------------------------------------------------------
# Crear directorio destino si no existe
# -----------------------------------------------------------
if [[ ! -d "${SKILLS_DEST}" ]]; then
    warn "El directorio destino no existe. Creandolo..."
    mkdir -p "${SKILLS_DEST}"
    ok "Directorio creado: ${SKILLS_DEST}"
else
    ok "Directorio destino ya existe."
fi

# -----------------------------------------------------------
# Copiar archivos
# -----------------------------------------------------------
echo ""
info "Copiando archivos..."

for FILE in "${FILES[@]}"; do
    SRC="${SKILLS_SRC}/${FILE}"
    DEST="${SKILLS_DEST}/${FILE}"

    if [[ ! -f "${SRC}" ]]; then
        warn "Archivo no encontrado, se omite: ${FILE}"
        continue
    fi

    if cp -f "${SRC}" "${DEST}"; then
        ok "Copiado: ${FILE}"
        COUNT=$((COUNT + 1))
    else
        err "No se pudo copiar: ${FILE}"
    fi
done

# -----------------------------------------------------------
# Resumen final
# -----------------------------------------------------------
echo ""
echo -e "${CYAN}=============================================================${NC}"
echo -e "${CYAN} RESUMEN DE INSTALACION${NC}"
echo -e "${CYAN}=============================================================${NC}"
echo " Destino : ${SKILLS_DEST}"
echo " Copiados: ${COUNT} / ${EXPECTED} archivos"
echo ""

if [[ "${COUNT}" -eq "${EXPECTED}" ]]; then
    ok "Todos los skills instalados correctamente."
else
    warn "Solo se copiaron ${COUNT} de ${EXPECTED} archivos. Revisa los errores arriba."
fi

echo ""
info "Archivos instalados en ${SKILLS_DEST}:"
for f in "${SKILLS_DEST}"/*.md; do
    [[ -f "$f" ]] && echo "       - $(basename "$f")"
done

# --- Detectar OS para mensaje de reinicio ---
echo ""
OS_TYPE="$(uname -s)"
if [[ "${OS_TYPE}" == "Darwin" ]]; then
    info "macOS detectado. Reinicia Claude Code (Cmd+Q y vuelve a abrir) para que detecte los nuevos skills."
else
    info "Linux detectado. Reinicia Claude Code para que detecte los nuevos skills."
fi

echo -e "${CYAN}=============================================================${NC}"
echo ""
