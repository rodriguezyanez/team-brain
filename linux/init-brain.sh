#!/usr/bin/env bash
# =============================================================
# init-brain.sh — Inicializa la base de datos "memory" en Neo4j
# Ejecutar UNA VEZ después de levantar el contenedor por primera vez
# =============================================================

set -e

NEO4J_HOST="${NEO4J_HOST:-localhost}"
NEO4J_PORT="${NEO4J_PORT:-7474}"
NEO4J_USER="${NEO4J_USER:-neo4j}"
NEO4J_PASS="${NEO4J_PASS:-team-brain-2025}"
BASE_URL="http://${NEO4J_HOST}:${NEO4J_PORT}"

echo "🧠 Inicializando Team Brain..."
echo "   Host: ${BASE_URL}"
echo ""

# ── Esperar a que Neo4j esté listo ────────────────────────────
echo "⏳ Esperando que Neo4j esté disponible..."
for i in $(seq 1 30); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${NEO4J_USER}:${NEO4J_PASS}" \
    "${BASE_URL}/db/system/tx" \
    -H "Content-Type: application/json" \
    -d '{"statements":[]}' 2>/dev/null || echo "000")
  if [ "$STATUS" = "200" ] || [ "$STATUS" = "201" ]; then
    echo "✅ Neo4j listo."
    break
  fi
  echo "   Intento ${i}/30... (status: ${STATUS})"
  sleep 3
done

# ── Función helper para ejecutar Cypher ──────────────────────
run_cypher() {
  local DB="$1"
  local QUERY="$2"
  local DESC="$3"

  echo -n "   → ${DESC}... "
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${NEO4J_USER}:${NEO4J_PASS}" \
    "${BASE_URL}/db/${DB}/tx/commit" \
    -H "Content-Type: application/json" \
    -d "{\"statements\":[{\"statement\":\"${QUERY}\"}]}")

  if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "201" ]; then
    echo "✅"
  else
    echo "⚠️  (HTTP ${RESPONSE})"
  fi
}

# ── Detectar edicion (Community vs Enterprise) ────────────────
echo ""
echo "Verificando edicion de Neo4j..."
USE_DB="neo4j"   # default para Community

ED_RESPONSE=$(curl -s \
  -u "${NEO4J_USER}:${NEO4J_PASS}" \
  "${BASE_URL}/db/system/tx/commit" \
  -H "Content-Type: application/json" \
  -d '{"statements":[{"statement":"CALL dbms.components() YIELD edition RETURN edition"}]}' 2>/dev/null || echo "")

if echo "$ED_RESPONSE" | grep -qi "enterprise"; then
  USE_DB="memory"
  echo "   Edicion Enterprise detectada. Creando base de datos 'memory'..."
  run_cypher "system" "CREATE DATABASE memory IF NOT EXISTS" "Crear DB memory"
  echo "   Esperando que la DB memory quede online..."
  sleep 8
else
  echo "   Edicion Community detectada. Usando base de datos 'neo4j'."
fi

# ── Crear constraints e índices ───────────────────────────────
echo ""
echo "🔑 Creando constraints..."

run_cypher "${USE_DB}" \
  "CREATE CONSTRAINT entity_name IF NOT EXISTS FOR (e:Entity) REQUIRE e.name IS UNIQUE" \
  "Constraint Entity.name único"

run_cypher "${USE_DB}" \
  "CREATE INDEX entity_type IF NOT EXISTS FOR (e:Entity) ON (e.entityType)" \
  "Índice Entity.entityType"

run_cypher "${USE_DB}" \
  "CREATE INDEX observation_content IF NOT EXISTS FOR (o:Observation) ON (o.content)" \
  "Índice Observation.content"

run_cypher "${USE_DB}" \
  "CREATE INDEX entity_created IF NOT EXISTS FOR (e:Entity) ON (e.createdAt)" \
  "Índice Entity.createdAt"

# ── Nodos base del equipo ─────────────────────────────────────
echo ""
echo "🏗️  Creando estructura base del equipo..."

run_cypher "${USE_DB}" \
  "MERGE (t:Entity {name: 'Team', entityType: 'Organization'}) SET t.createdAt = datetime(), t.description = 'Equipo de desarrollo'" \
  "Nodo Team"

run_cypher "${USE_DB}" \
  "MERGE (p:Entity {name: 'Architecture', entityType: 'Topic'}) SET p.createdAt = datetime()" \
  "Nodo Architecture"

run_cypher "${USE_DB}" \
  "MERGE (d:Entity {name: 'Decisions', entityType: 'Topic'}) SET d.createdAt = datetime()" \
  "Nodo Decisions"

run_cypher "${USE_DB}" \
  "MERGE (c:Entity {name: 'Conventions', entityType: 'Topic'}) SET c.createdAt = datetime()" \
  "Nodo Conventions"

echo ""
echo "═══════════════════════════════════════════════"
echo "✅ Team Brain inicializado correctamente"
echo ""
echo "   Neo4j Browser: http://${NEO4J_HOST}:${NEO4J_PORT}"
echo "   Usuario:        ${NEO4J_USER}"
echo "   Base de datos:  ${USE_DB}"
echo "   Bolt URI:       bolt://${NEO4J_HOST}:7687"
echo "═══════════════════════════════════════════════"
echo ""
echo "Próximo paso: registra el MCP en Claude Code:"
echo ""
echo "  claude mcp add-json \"team-brain\" '{\"command\":\"npx\",\"args\":[\"-y\",\"@knowall-ai/mcp-neo4j-agent-memory\"],\"env\":{\"NEO4J_URI\":\"bolt://localhost:7687\",\"NEO4J_USERNAME\":\"${NEO4J_USER}\",\"NEO4J_PASSWORD\":\"${NEO4J_PASS}\",\"NEO4J_DATABASE\":\"${USE_DB}\"}}'"
