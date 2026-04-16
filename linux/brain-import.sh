#!/usr/bin/env bash
# =============================================================
# brain-import.sh — Importa y mergea un export JSON en Neo4j
#
# Uso:
#   ./brain-import.sh <archivo.json>
#
# Estrategia de merge (nunca sobreescribe, solo agrega):
#   - Entidad nueva     -> se crea con todas sus propiedades
#   - Entidad existente -> se agregan solo las propiedades (keys)
#                         que no existan en el master
#   - Relaciones        -> MERGE por (from, relationType, to)
#
# Requiere: curl, jq
# =============================================================

NEO4J_URI="${NEO4J_URI:-http://localhost:7474}"
NEO4J_USER="${NEO4J_USER:-neo4j}"
NEO4J_PASS="${NEO4J_PASS:-team-brain-2025}"
NEO4J_DB="${NEO4J_DB:-neo4j}"
TX_ENDPOINT="${NEO4J_URI}/db/${NEO4J_DB}/tx/commit"
AUTH_HEADER="Authorization: Basic $(echo -n "${NEO4J_USER}:${NEO4J_PASS}" | base64)"

INPUT_FILE="$1"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}Team Brain -- Importacion y merge de grafo${NC}"
echo ""

# ── Validaciones ──────────────────────────────────────────────
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}[ERROR] '$cmd' no encontrado. Instalalo primero.${NC}"
        exit 1
    fi
done

if [[ -z "$INPUT_FILE" ]]; then
    echo -e "${RED}[ERROR] Debes indicar el archivo a importar.${NC}"
    echo "        Uso: ./brain-import.sh <archivo.json>"
    echo ""
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo -e "${RED}[ERROR] Archivo no encontrado: ${INPUT_FILE}${NC}"
    exit 1
fi

if ! jq . "$INPUT_FILE" &>/dev/null; then
    echo -e "${RED}[ERROR] El archivo no es JSON valido: ${INPUT_FILE}${NC}"
    exit 1
fi

# ── Info del export ───────────────────────────────────────────
EXPORTED_AT=$(jq -r '.meta.exportedAt'       "$INPUT_FILE")
EXPORTED_BY=$(jq -r '.meta.exportedBy'       "$INPUT_FILE")
EXPORTED_USER=$(jq -r '.meta.exportedByUser' "$INPUT_FILE")
ENTITY_COUNT=$(jq -r '.meta.entityCount'     "$INPUT_FILE")
CONN_COUNT=$(jq -r '.meta.connectionCount'   "$INPUT_FILE")

echo "   Archivo    : $INPUT_FILE"
echo "   Exportado  : $EXPORTED_AT"
echo "   Origen     : ${EXPORTED_BY} / ${EXPORTED_USER}"
echo "   Entidades  : $ENTITY_COUNT"
echo "   Relaciones : $CONN_COUNT"
echo ""

# ── Verificar Neo4j ───────────────────────────────────────────
echo "   Verificando conexion con Neo4j..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    --connect-timeout 5 \
    "${NEO4J_URI}/" 2>/dev/null)

if [[ "$HTTP_STATUS" -ge 400 ]] || [[ -z "$HTTP_STATUS" ]]; then
    echo -e "${RED}[ERROR] Neo4j no responde en ${NEO4J_URI} (HTTP ${HTTP_STATUS})${NC}"
    echo -e "${YELLOW}        Ejecuta 'docker compose up -d' y vuelve a intentarlo.${NC}"
    echo ""
    exit 1
fi
echo -e "${GREEN}   Neo4j disponible.${NC}"
echo ""

# ── Funcion Cypher ────────────────────────────────────────────
run_cypher() {
    local statement="$1"
    local parameters="${2:-{}}"
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
        echo "NEO4J_ERROR: $msg"
        return 1
    fi
    echo "$response"
    return 0
}

# ── Merge de entidades ────────────────────────────────────────
echo -e "${CYAN}   Procesando entidades...${NC}"
ENT_NEW=0
ENT_UPD=0
ENT_SKIP=0
PROPS_ADDED=0

ENTITY_TOTAL=$(jq '.entities | length' "$INPUT_FILE")

for ((i=0; i<ENTITY_TOTAL; i++)); do
    NAME=$(jq -r ".entities[$i].name" "$INPUT_FILE")

    # Soporta formato nuevo (properties) y formato legacy (campos directos)
    if jq -e ".entities[$i].properties" "$INPUT_FILE" &>/dev/null; then
        INCOMING_PROPS=$(jq -c ".entities[$i].properties" "$INPUT_FILE")
    else
        INCOMING_PROPS=$(jq -c "{name: .entities[$i].name, entityType: .entities[$i].entityType}" "$INPUT_FILE")
    fi

    # Traer propiedades actuales del master
    MASTER_RESP=$(run_cypher \
        "MATCH (e:Entity {name: \$name}) RETURN properties(e) AS props" \
        "{\"name\": $(jq -n --arg v "$NAME" '$v')}")

    if echo "$MASTER_RESP" | grep -q "NEO4J_ERROR"; then
        echo -e "${RED}   [FAIL] $NAME: error consultando master${NC}"
        continue
    fi

    ENTITY_EXISTS=$(echo "$MASTER_RESP" | jq '.results[0].data | length')
    MASTER_PROPS=$(echo "$MASTER_RESP" | jq -c '.results[0].data[0].row[0] // {}')

    if [[ "$ENTITY_EXISTS" -eq 0 ]]; then
        # Entidad nueva: crear con todas sus propiedades
        PARAMS=$(jq -n \
            --arg name "$NAME" \
            --argjson props "$INCOMING_PROPS" \
            '{"name":$name,"props":$props}')
        RESULT=$(run_cypher \
            "MERGE (e:Entity {name: \$name}) SET e += \$props" \
            "$PARAMS")
        if echo "$RESULT" | grep -q "NEO4J_ERROR"; then
            echo -e "${RED}   [FAIL] $NAME${NC}"
        else
            PROP_COUNT=$(echo "$INCOMING_PROPS" | jq 'keys | length')
            echo -e "${GREEN}   [NEW]  $NAME${NC}"
            ((ENT_NEW++))
            PROPS_ADDED=$((PROPS_ADDED + PROP_COUNT))
        fi

    else
        # Entidad existente: calcular propiedades ausentes en master
        NEW_PROPS=$(jq -n \
            --argjson incoming "$INCOMING_PROPS" \
            --argjson master   "$MASTER_PROPS" \
            'to_entries as $inc |
             ($master | keys) as $masterKeys |
             [ $inc[] | select(.key as $k | $masterKeys | index($k) == null) ] |
             from_entries')
        NEW_COUNT=$(echo "$NEW_PROPS" | jq 'keys | length')

        if [[ "$NEW_COUNT" -gt 0 ]]; then
            PARAMS=$(jq -n \
                --arg name "$NAME" \
                --argjson newProps "$NEW_PROPS" \
                '{"name":$name,"newProps":$newProps}')
            RESULT=$(run_cypher \
                "MATCH (e:Entity {name: \$name}) SET e += \$newProps" \
                "$PARAMS")
            if echo "$RESULT" | grep -q "NEO4J_ERROR"; then
                echo -e "${RED}   [FAIL] $NAME${NC}"
            else
                NEW_KEYS=$(echo "$NEW_PROPS" | jq -r 'keys | join(", ")')
                echo -e "${YELLOW}   [UPD]  $NAME (+${NEW_COUNT} props: ${NEW_KEYS})${NC}"
                ((ENT_UPD++))
                PROPS_ADDED=$((PROPS_ADDED + NEW_COUNT))
            fi
        else
            ((ENT_SKIP++))
        fi
    fi
done

echo ""
echo -e "${GREEN}   Entidades nuevas       : $ENT_NEW${NC}"
echo -e "${YELLOW}   Entidades actualizadas : $ENT_UPD${NC}"
echo    "   Entidades sin cambios  : $ENT_SKIP"
echo -e "${GREEN}   Propiedades agregadas  : $PROPS_ADDED${NC}"
echo ""

# ── Merge de relaciones ───────────────────────────────────────
echo -e "${CYAN}   Procesando relaciones...${NC}"
REL_NEW=0
REL_SKIP=0

CONN_TOTAL=$(jq '.connections | length' "$INPUT_FILE")

for ((i=0; i<CONN_TOTAL; i++)); do
    FROM=$(jq -r ".connections[$i].from"          "$INPUT_FILE")
    REL_TYPE=$(jq -r ".connections[$i].relationType" "$INPUT_FILE")
    TO=$(jq -r ".connections[$i].to"              "$INPUT_FILE")
    REL_SAFE=$(echo "$REL_TYPE" | tr -cd 'A-Z0-9_')

    PARAMS=$(jq -n --arg from "$FROM" --arg to "$TO" '{"from":$from,"to":$to}')

    CHECK_RESP=$(run_cypher \
        "MATCH (a:Entity {name: \$from})-[r:${REL_SAFE}]->(b:Entity {name: \$to}) RETURN count(r) AS cnt" \
        "$PARAMS")
    EXISTS=$(echo "$CHECK_RESP" | jq -r '.results[0].data[0].row[0] // 0')

    if [[ "$EXISTS" -gt 0 ]]; then
        ((REL_SKIP++))
    else
        RESULT=$(run_cypher \
            "MATCH (a:Entity {name: \$from}), (b:Entity {name: \$to}) MERGE (a)-[:${REL_SAFE}]->(b)" \
            "$PARAMS")
        if echo "$RESULT" | grep -q "NEO4J_ERROR"; then
            echo -e "${RED}   [FAIL] $FROM -[$REL_SAFE]-> $TO${NC}"
        else
            echo -e "${GREEN}   [NEW]  $FROM -[$REL_SAFE]-> $TO${NC}"
            ((REL_NEW++))
        fi
    fi
done

echo ""
echo    "   Relaciones nuevas        : $REL_NEW"
echo    "   Relaciones ya existentes : $REL_SKIP"
echo ""

# ── Resumen ───────────────────────────────────────────────────
echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}   Import completado.${NC}"
echo    "   Entidades  : $ENT_NEW nuevas, $ENT_UPD actualizadas, $ENT_SKIP sin cambios"
echo    "   Relaciones : $REL_NEW nuevas, $REL_SKIP sin cambios"
echo    "   Propiedades agregadas: $PROPS_ADDED"
echo -e "${CYAN}======================================================${NC}"
echo ""
exit 0
