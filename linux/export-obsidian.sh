#!/usr/bin/env bash
# =============================================================
# export-obsidian.sh — Exporta Neo4j a Obsidian vault (Linux/macOS)
# Usa Python3 para parsear JSON de la API HTTP de Neo4j.
#
# Uso:
#   ./export-obsidian.sh
#   ./export-obsidian.sh ./mi-vault localhost 7474 neo4j mipass
#
# Requisito: Neo4j corriendo + Python3 instalado
# =============================================================

set -euo pipefail

OUTPUT_DIR="${1:-./vault}"
NEO4J_HOST="${2:-localhost}"
NEO4J_PORT="${3:-7474}"
NEO4J_USER="${4:-neo4j}"
NEO4J_PASS="${5:-team-brain-2025}"

# Detectar password desde docker-compose.yml
if [ "$NEO4J_PASS" = "team-brain-2025" ] && [ -f "docker-compose.yml" ]; then
    DETECTED=$(grep "NEO4J_AUTH" docker-compose.yml 2>/dev/null | sed 's/.*neo4j\///' | tr -d ' "' | head -1) || true
    if [ -n "$DETECTED" ]; then
        NEO4J_PASS="$DETECTED"
    fi
fi

# Verificar Python3
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] Python3 no encontrado. Instala Python3 para usar este script."
    echo "        En macOS: brew install python3"
    echo "        En Ubuntu/Debian: sudo apt install python3"
    exit 1
fi

echo ""
echo "====================================================="
echo "  Team Brain — Exportacion a Obsidian Vault"
echo "====================================================="
echo ""

# Exportar via Python3
OUTPUT_DIR="$OUTPUT_DIR" \
NEO4J_HOST="$NEO4J_HOST" \
NEO4J_PORT="$NEO4J_PORT" \
NEO4J_USER="$NEO4J_USER" \
NEO4J_PASS="$NEO4J_PASS" \
python3 << 'PYTHON'
import json, os, re, sys, urllib.request, urllib.error, base64
from datetime import datetime

output_dir  = os.environ['OUTPUT_DIR']
neo4j_host  = os.environ['NEO4J_HOST']
neo4j_port  = os.environ['NEO4J_PORT']
neo4j_user  = os.environ['NEO4J_USER']
neo4j_pass  = os.environ['NEO4J_PASS']

base_url = f"http://{neo4j_host}:{neo4j_port}/db/neo4j/tx/commit"
token    = base64.b64encode(f"{neo4j_user}:{neo4j_pass}".encode()).decode()
headers  = {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": f"Basic {token}"
}

def neo4j_query(cypher):
    body = json.dumps({"statements": [{"statement": cypher}]}).encode()
    req  = urllib.request.Request(base_url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read())
    except urllib.error.URLError as e:
        print(f"[ERROR] No se pudo conectar a Neo4j: {e}")
        sys.exit(1)

def safe_name(name):
    return re.sub(r'[\\/:*?"<>|]', '_', name)

# Verificar conexion
print("[1/5] Verificando conexion con Neo4j...")
neo4j_query("RETURN 1")
print(f"  [OK] Neo4j disponible en {neo4j_host}:{neo4j_port}")

# Preparar directorio
print(f"[2/5] Preparando directorio: {output_dir}")
import shutil
if os.path.exists(output_dir):
    shutil.rmtree(output_dir)
os.makedirs(output_dir)
print("  [OK] Directorio listo.")

# Consultar nodos
print("[3/5] Consultando nodos...")
nodes_resp = neo4j_query("MATCH (n:Entity) RETURN n ORDER BY n.entityType, n.name")
node_data  = nodes_resp["results"][0]["data"]
print(f"  [OK] {len(node_data)} nodos encontrados.")

# Consultar relaciones
print("[4/5] Consultando relaciones...")
rels_resp = neo4j_query("MATCH (n:Entity)-[r]->(m:Entity) RETURN n.name, type(r), m.name ORDER BY n.name")
rels_data = rels_resp["results"][0]["data"]

outgoing = {}
incoming = {}
for row in rels_data:
    src, rel, dst = row["row"]
    outgoing.setdefault(src, []).append({"rel": rel, "node": dst})
    incoming.setdefault(dst, []).append({"rel": rel, "node": src})
print(f"  [OK] {len(rels_data)} relaciones indexadas.")

# Generar archivos
print("[5/5] Generando archivos Markdown...")
skip_props = {"name", "entityType", "updatedAt", "createdAt"}
by_type    = {}

for item in node_data:
    node        = item["row"][0]
    name        = node.get("name", "Unknown")
    entity_type = node.get("entityType", "Unknown")
    safe        = safe_name(name)
    file_path   = os.path.join(output_dir, f"{safe}.md")

    by_type.setdefault(entity_type, []).append(name)

    lines = []
    lines.append(f"# {name}\n")
    lines.append(f"**Tipo:** `{entity_type}`")
    if node.get("updatedAt"):
        lines.append(f"**Actualizado:** {node['updatedAt']}")
    lines.append("")

    # Propiedades
    props = {k: v for k, v in node.items() if k not in skip_props and v}
    if props:
        lines.append("## Propiedades\n")
        for k, v in props.items():
            lines.append(f"- **{k}**: {v}")
        lines.append("")

    # Relaciones salientes
    if name in outgoing:
        lines.append("## Conecta con\n")
        for r in outgoing[name]:
            lines.append(f"- [[{r['node']}]] `{r['rel']}`")
        lines.append("")

    # Relaciones entrantes
    if name in incoming:
        lines.append("## Referenciado desde\n")
        for r in incoming[name]:
            lines.append(f"- [[{r['node']}]] `{r['rel']}`")
        lines.append("")

    with open(file_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"  -> {safe}.md")

# Generar README.md
readme_lines = [
    "# Team Brain KLAP BYSF — Knowledge Vault\n",
    f"Exportado desde Neo4j el {datetime.now().strftime('%Y-%m-%d %H:%M')}",
    f"Total de nodos: {len(node_data)}",
    "",
    "---\n",
    "## Mapa del grafo por tipo\n"
]
for entity_type in sorted(by_type.keys()):
    readme_lines.append(f"### {entity_type}\n")
    for node_name in sorted(by_type[entity_type]):
        readme_lines.append(f"- [[{node_name}]]")
    readme_lines.append("")

readme_path = os.path.join(output_dir, "README.md")
with open(readme_path, "w", encoding="utf-8") as f:
    f.write("\n".join(readme_lines))

print("")
print("=====================================================")
print(f"  Vault generado: {output_dir}")
print(f"  Nodos exportados : {len(node_data)}")
print(f"  Relaciones       : {len(rels_data)}")
print("=====================================================")
print("")
print("  Para abrir en Obsidian:")
print("    1. Abri Obsidian")
print("    2. Archivo → Abrir vault → seleccionar la carpeta 'vault/'")
print("    3. Abre README.md para el mapa de navegacion")
print("")
print("  Nota: vault/ esta en .gitignore - no se sube al repositorio.")
print("")
PYTHON
