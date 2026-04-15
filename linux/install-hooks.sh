#!/bin/bash
# =============================================================
# install-hooks.sh — Instala Guardian Angel en un proyecto
#
# Uso:
#   ./install-hooks.sh                    <- instala en el directorio actual
#   ./install-hooks.sh /ruta/al/proyecto  <- instala en el proyecto indicado
#
# Para desinstalar:
#   rm /ruta/proyecto/.git/hooks/pre-commit
#   rm /ruta/proyecto/.git/hooks/review-prompt.md
# =============================================================

set -e

TEAM_BRAIN_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_SRC="$TEAM_BRAIN_DIR/hooks"
PROJECT_DIR="${1:-$(pwd)}"
GIT_HOOKS="$PROJECT_DIR/.git/hooks"

echo ""
echo "=== Instalando Guardian Angel KLAP BYSF ==="
echo ""

# -- Verificar que es un repo git --
if [ ! -d "$PROJECT_DIR/.git" ]; then
  echo "[ERROR] No se encontró .git en: $PROJECT_DIR"
  echo "        Indicá el directorio raíz de tu proyecto:"
  echo "        ./install-hooks.sh ~/proyectos/mi-servicio"
  exit 1
fi

# -- Verificar archivos fuente --
if [ ! -f "$HOOKS_SRC/pre-commit.sh" ]; then
  echo "[ERROR] hooks/pre-commit.sh no encontrado en $HOOKS_SRC"
  exit 1
fi
if [ ! -f "$HOOKS_SRC/review-prompt.md" ]; then
  echo "[ERROR] hooks/review-prompt.md no encontrado en $HOOKS_SRC"
  exit 1
fi

# -- Backup del hook existente --
if [ -f "$GIT_HOOKS/pre-commit" ]; then
  cp "$GIT_HOOKS/pre-commit" "$GIT_HOOKS/pre-commit.bak"
  echo "[INFO] Backup creado: .git/hooks/pre-commit.bak"
fi

# -- Copiar hook y prompt --
cp "$HOOKS_SRC/pre-commit.sh"    "$GIT_HOOKS/pre-commit"
cp "$HOOKS_SRC/review-prompt.md" "$GIT_HOOKS/review-prompt.md"
chmod +x "$GIT_HOOKS/pre-commit"

echo "[OK] Hook instalado en: $GIT_HOOKS/pre-commit"
echo "[OK] Prompt copiado en: $GIT_HOOKS/review-prompt.md"
echo ""
echo "=== Guardian Angel activo en: $PROJECT_DIR ==="
echo ""
echo "  Cada commit en archivos .java/.kt será revisado."
echo "  Commit urgente sin revisión: git commit --no-verify"
echo "  Desinstalar: rm $GIT_HOOKS/pre-commit"
echo ""
