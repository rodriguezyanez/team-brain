#!/usr/bin/env bash
# =============================================================
# brain-export.sh — Exporta todo el grafo de Neo4j a JSON
#
# Uso:
#   ./brain-export.sh [archivo-salida.json]
#
# Exporta todas las entidades con sus propiedades completas
# y todas las relaciones del grafo local.
#
# Formato del export:
#   entities[].properties -> todas las propiedades del nodo
#   connections[]         -> relaciones (from, relationType, to)
#
# Requiere: curl, jq
# =============================================================

NEO4J_URI="${NEO4J_URI:-http://localhost:7474}"
NEO4J_USER="${NEO4J_USER:-neo4j}"
NEO4J_PASS="${NEO4J_PASS:-team-brain-2025}"
NEO4J_DB="${NEO4J_DB:-neo4j}"
TX_ENDPOINT="${NEO4J_URI}/db/${NEO4J_DB}/tx/commit"
AUTH_HEADER="Authorization: Basic $(echo -n "${NEO4J_USER}:${NEO4J_PASS}" | base64)"

OUTPUT_FILE="${1:-teambrain-export-$(hostname)-$(date +%Y%m%d-%H%M%S).json}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}Team Brain -- Exportacion de grafo${NC}"
echo ""

for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}[ERROR] '$cmd' no encontrado. Instalalo primero.${NC}"
        exit 1
    fi
done

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

run_cypher() {
    local statement="$1"
    local body
    body=$(jq -n --arg stmt "$statement" '{"statements":[{"statement":$stmt}]}')
    curl -s -X POST "$TX_ENDPOINT" \
        -H "$AUTH_HEADER" \
        -H "Content-Type: application/json" \
        -d "$body"
}

# ── Exportar entidades (todas las propiedades del nodo) ───────
echo "   Exportando entidades..."

# properties(e) retorna TODAS las propiedades del nodo, no solo campos fijos
ENTITIES_RESP=$(run_cypher \
    "MATCH (e:Entity) RETURN properties(e) AS props ORDER BY e.name")

ERRORS=$(echo "$ENTITIES_RESP" | jq -r '.errors | length')
if [[ "$ERRORS" -gt 0 ]]; then
    MSG=$(echo "$ENTITIES_RESP" | jq -r '.errors[0].message')
    echo -e "${RED}[ERROR] Fallo al exportar entidades: $MSG${NC}"
    exit 1
fi

# row[0] es el objeto completo de propiedades del nodo
ENTITIES_JSON=$(echo "$ENTITIES_RESP" | jq '[.results[0].data[] | {
    name:       (.row[0].name // ""),
    entityType: (.row[0].entityType // ""),
    properties: .row[0]
}]')
ENTITY_COUNT=$(echo "$ENTITIES_JSON" | jq 'length')
echo -e "${GREEN}   Entidades encontradas: ${ENTITY_COUNT}${NC}"

# ── Exportar relaciones ───────────────────────────────────────
echo "   Exportando relaciones..."
CONNS_RESP=$(run_cypher \
    "MATCH (a:Entity)-[r]->(b:Entity) RETURN a.name AS from, type(r) AS relationType, b.name AS to ORDER BY a.name, type(r), b.name")

ERRORS=$(echo "$CONNS_RESP" | jq -r '.errors | length')
if [[ "$ERRORS" -gt 0 ]]; then
    MSG=$(echo "$CONNS_RESP" | jq -r '.errors[0].message')
    echo -e "${RED}[ERROR] Fallo al exportar relaciones: $MSG${NC}"
    exit 1
fi

CONNECTIONS_JSON=$(echo "$CONNS_RESP" | jq '[.results[0].data[] | {
    from:         .row[0],
    relationType: .row[1],
    to:           .row[2]
}]')
CONN_COUNT=$(echo "$CONNECTIONS_JSON" | jq 'length')
echo -e "${GREEN}   Relaciones encontradas: ${CONN_COUNT}${NC}"
echo ""

# ── Construir y escribir JSON ─────────────────────────────────
EXPORTED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
    --arg exportedAt      "$EXPORTED_AT" \
    --arg exportedBy      "$(hostname)" \
    --arg exportedByUser  "${USER:-$(whoami)}" \
    --arg neo4jUri        "$NEO4J_URI" \
    --argjson entityCount     "$ENTITY_COUNT" \
    --argjson connectionCount "$CONN_COUNT" \
    --argjson entities    "$ENTITIES_JSON" \
    --argjson connections "$CONNECTIONS_JSON" \
    '{
        meta: {
            exportedAt:       $exportedAt,
            exportedBy:       $exportedBy,
            exportedByUser:   $exportedByUser,
            neo4jUri:         $neo4jUri,
            teamBrainVersion: "3.0",
            entityCount:      $entityCount,
            connectionCount:  $connectionCount
        },
        entities:    $entities,
        connections: $connections
    }' > "$OUTPUT_FILE"

echo -e "${GREEN}   [OK] Export guardado en: ${OUTPUT_FILE}${NC}"
echo ""
echo -e "${YELLOW}   Compartilo con el responsable del master y ejecuta:${NC}"
echo -e "${YELLOW}     ./brain-import.sh ${OUTPUT_FILE}${NC}"
echo ""
exit 0
