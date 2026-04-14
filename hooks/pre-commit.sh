#!/bin/bash
# =============================================================
# Guardian Angel — Hook pre-commit KLAP BYSF
# Revisa el diff staged contra las reglas del equipo via Claude.
#
# Instalación: ./install-hooks.sh /ruta/al/proyecto
# Bypass urgente: git commit --no-verify
# =============================================================

# ── Obtener diff staged de archivos Java ─────────────────────
DIFF=$(git diff --cached --diff-filter=ACMR -- "*.java" "*.kt" "*.groovy" 2>/dev/null)

if [ -z "$DIFF" ]; then
  # Sin cambios en código Java/Kotlin → permitir commit sin revisión
  exit 0
fi

# ── Localizar review-prompt.md ────────────────────────────────
# El hook está en .git/hooks/pre-commit y review-prompt.md se copia junto a él
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
REVIEW_PROMPT="$HOOK_DIR/review-prompt.md"

if [ ! -f "$REVIEW_PROMPT" ]; then
  echo "[GGA] WARN: review-prompt.md no encontrado en $HOOK_DIR"
  echo "[GGA] Salteando revisión. Para reinstalar: install-hooks.sh"
  exit 0
fi

# ── Verificar Claude CLI ──────────────────────────────────────
if ! command -v claude &> /dev/null; then
  echo "[GGA] WARN: Claude CLI no encontrado. Salteando revisión."
  echo "     Instala con: npm install -g @anthropic-ai/claude-code"
  exit 0
fi

# ── Construir prompt completo ─────────────────────────────────
PROMPT_CONTENT=$(cat "$REVIEW_PROMPT")
FULL_PROMPT="${PROMPT_CONTENT}

## Diff a revisar

\`\`\`diff
${DIFF}
\`\`\`"

# ── Llamar a Claude en modo no-interactivo ───────────────────
echo ""
echo "🔍 Guardian Angel revisando el commit..."

RESULT=$(echo "$FULL_PROMPT" | claude --print 2>&1) || true

# ── Parsear resultado ─────────────────────────────────────────
if echo "$RESULT" | grep -q "GUARDIAN_ANGEL_RESULT=FAIL"; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚫  Guardian Angel bloqueó el commit — violaciones encontradas"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "$RESULT" | grep -v "^GUARDIAN_ANGEL_RESULT"
  echo ""
  echo "Corregí las violaciones y volvé a hacer commit."
  echo "Commit urgente sin revisión: git commit --no-verify"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi

if echo "$RESULT" | grep -q "GUARDIAN_ANGEL_RESULT=PASS"; then
  echo ""
  echo "✅ Guardian Angel: commit aprobado"
  echo ""
  echo "$RESULT" | grep -v "^GUARDIAN_ANGEL_RESULT"
  exit 0
fi

# Claude no devolvió resultado reconocible → fail-open (no bloquear)
echo ""
echo "[GGA] WARN: Revisión sin resultado reconocible. Permitiendo commit (fail-open)."
echo "$RESULT"
exit 0
