#!/usr/bin/env bash
# =============================================================
# brain-sync.sh — Sincroniza memorias pendientes con Neo4j
#
# Uso:
#   ./brain-sync.sh
#
# Requiere: curl, jq
# =============================================================

NEO4J_URI="${NEO4J_URI:-http://localhost:7474}"
NEO4J_USER="${NEO4J_USER:-neo4j}"
NEO4J_PASS="${NEO4J_PASS:-team-brain-2025}"
NEO4J_DB="${NEO4J_DB:-neo4j}"
QUEUE_FILE="${HOME}/.claude/pending-memories.jsonl"
TX_ENDPOINT="${NEO4J_URI}/db/${NEO4J_DB}/tx/commit"
AUTH_HEADER="Authorization: Basic $(echo -n "${NEO4J_USER}:${NEO4J_PASS}" | base64)"

# ── Colores ───────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}Team Brain — Sincronizacion de memoria pendiente${NC}"
echo ""

# ── Dependencias ──────────────────────────────────────────────
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}[ERROR] '$cmd' no encontrado. Instálalo primero.${NC}"
        exit 1
    fi
done

# ── Verificar archivo de cola ─────────────────────────────────
if [[ ! -f "$QUEUE_FILE" ]]; then
    echo -e "${GREEN}[OK] No hay memorias pendientes.${NC}"
    echo ""
    exit 0
fi

LINES=$(grep -c . "$QUEUE_FILE" 2>/dev/null || echo 0)
if [[ "$LINES" -eq 0 ]]; then
    echo -e "${GREEN}[OK] No hay memorias pendientes.${NC}"
    rm -f "$QUEUE_FILE"
    echo ""
    exit 0
fi

echo "   Memorias en cola: $LINES"
echo ""

# ── Verificar Neo4j ───────────────────────────────────────────
echo "   Verificando conexion con Neo4j..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "$AUTH_HEADER" \
    --connect-timeout 5 \
    "${NEO4J_URI}/db/${NEO4J_DB}" 2>/dev/null)

if [[ "$HTTP_STATUS" -ge 400 ]] || [[ -z "$HTTP_STATUS" ]]; then
    echo -e "${RED}[ERROR] Neo4j no responde en ${NEO4J_URI} (HTTP ${HTTP_STATUS})${NC}"
    echo -e "${YELLOW}        Ejecuta 'docker compose up -d' y vuelve a intentarlo.${NC}"
    echo ""
    exit 1
fi
echo -e "${GREEN}   Neo4j disponible.${NC}"
echo ""

# ── Función Cypher ────────────────────────────────────────────
run_cypher() {
    local statement="$1"
    local parameters="$2"
    local body
    body=$(jq -n \
        --arg stmt "$statement" \
        --argjson params "$parameters" \
        '{"statements":[{"statement":$stmt,"parameters":$params}]}')

    local response
    response=$(curl -s -X POST "$TX_ENDPOINT" \
        -H "$AUTH_HEADER" \
        -H "Content-Type: application/json" \
        -d "$body")

    local errors
    errors=$(echo "$response" | jq -r '.errors | length')
    if [[ "$errors" -gt 0 ]]; then
        local msg
        msg=$(echo "$response" | jq -r '.errors[0].message')
        echo "ERROR: $msg"
        return 1
    fi
    return 0
}

# ── Procesar cola ─────────────────────────────────────────────
OK=0
FAILED=0
PENDING_LINES=""

while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    TYPE=$(echo "$line" | jq -r '.type')
    ERROR=""

    case "$TYPE" in
        memory)
            NAME=$(echo "$line" | jq -r '.name')
            ENTITY_TYPE=$(echo "$line" | jq -r '.entityType')
            OBSERVATIONS=$(echo "$line" | jq '.observations')

            CYPHER="MERGE (e:Entity {name: \$name})
SET e.entityType = \$entityType
WITH e, \$observations AS newObs
CALL {
  WITH e, newObs
  UNWIND newObs AS obs
  WITH e, obs
  WHERE NOT obs IN coalesce(e.observations, [])
  SET e.observations = coalesce(e.observations, []) + [obs]
}
RETURN e.name AS name"

            PARAMS=$(jq -n \
                --arg name "$NAME" \
                --arg entityType "$ENTITY_TYPE" \
                --argjson observations "$OBSERVATIONS" \
                '{"name":$name,"entityType":$entityType,"observations":$observations}')

            ERROR=$(run_cypher "$CYPHER" "$PARAMS" 2>&1)
            LABEL="$NAME"
            ;;

        connection)
            FROM=$(echo "$line" | jq -r '.from')
            TO=$(echo "$line" | jq -r '.to')
            REL=$(echo "$line" | jq -r '.relationType' | tr -cd 'A-Z0-9_')

            CYPHER="MATCH (a:Entity {name: \$from}), (b:Entity {name: \$to}) MERGE (a)-[:${REL}]->(b)"
            PARAMS=$(jq -n --arg from "$FROM" --arg to "$TO" '{"from":$from,"to":$to}')

            ERROR=$(run_cypher "$CYPHER" "$PARAMS" 2>&1)
            LABEL="${FROM} -> ${TO}"
            ;;

        *)
            ERROR="Tipo desconocido: $TYPE"
            LABEL="?"
            ;;
    esac

    if [[ -z "$ERROR" ]]; then
        echo -e "${GREEN}   [OK] $LABEL${NC}"
        ((OK++))
    else
        echo -e "${RED}   [FAIL] $LABEL — $ERROR${NC}"
        ((FAILED++))
        PENDING_LINES="${PENDING_LINES}${line}"$'\n'
    fi

done < "$QUEUE_FILE"

# ── Reescribir archivo ────────────────────────────────────────
if [[ -n "$PENDING_LINES" ]]; then
    printf '%s' "$PENDING_LINES" > "$QUEUE_FILE"
else
    rm -f "$QUEUE_FILE"
fi

echo ""
echo -e "${CYAN}   Sincronizadas: ${OK}  |  Fallidas (conservadas): ${FAILED}${NC}"
echo ""

if [[ "$FAILED" -gt 0 ]]; then
    echo -e "${YELLOW}   Las entradas fallidas permanecen en:${NC}"
    echo -e "${YELLOW}   $QUEUE_FILE${NC}"
    echo ""
    exit 1
fi

echo -e "${GREEN}[OK] Toda la memoria pendiente fue sincronizada con Neo4j.${NC}"
echo ""
exit 0
