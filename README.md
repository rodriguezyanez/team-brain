# Team Brain — Neo4j Knowledge Graph

Sistema de memoria compartida para el equipo de desarrollo KLAP BYSF.
Combina Neo4j, Claude Code y MCP para que el asistente recuerde el contexto
del equipo entre sesiones y entre devs.

```
Dev 1 (Claude Code)
Dev 2 (Claude Code)  ──→  MCP team-brain  ──→  Neo4j (bolt://localhost:7687)
Dev 3 (Claude Code)
```

> **Guía de instalación paso a paso → [`GUIA-PRACTICA.md`](GUIA-PRACTICA.md)**

---

## Requisitos

- Docker Desktop
- Node.js >= 18
- Claude Code: `npm install -g @anthropic-ai/claude-code`

---

## Estructura del proyecto

```
team-brain/
│
├── docker-compose.yml       Neo4j 5.18 Community — puertos 7474 y 7687
│                            4 volúmenes persistentes (datos sobreviven a reinicios)
│
├── CLAUDE.md                System prompt del equipo para Claude Code
│                            Instalar en: ~/.claude/CLAUDE.md  (Linux/macOS)
│                                         %USERPROFILE%\.claude\CLAUDE.md  (Windows)
│
│── Windows ──────────────────────────────────────────────────────────────────
├── setup.bat / setup.ps1    Instalador/desinstalador — setup completo en un comando
│                            setup.bat --uninstall para desinstalar y restaurar config
├── brain.bat / brain.ps1    Operaciones diarias: up, down, restart, status,
│                            logs, browser, mcp, update, sync, export, import
├── brain-update.bat/.ps1    Sincronización incremental de Neo4j (preserva memoria)
├── brain-export.ps1         Exporta grafo completo a JSON (brain.bat export)
├── brain-import.ps1         Mergea export de otro dev en Neo4j (brain.bat import)
├── init-brain.bat           Inicialización de Neo4j — ejecutar UNA vez
├── init-brain.ps1           Versión PowerShell — detecta Community vs Enterprise
├── enrich-brain.bat         Carga arquitectura de referencia KLAP BYSF
├── backup.bat / backup.ps1  Backup y restore de volúmenes
│
│── Linux / macOS ────────────────────────────────────────────────────────────
├── setup.sh                 Instalador unificado — setup completo en un comando
├── init-brain.sh            Inicialización — detecta Community vs Enterprise
├── enrich-brain.sh          Carga arquitectura de referencia KLAP BYSF
├── brain-update.sh          Sincronización incremental de Neo4j (preserva memoria)
├── brain-export.sh          Exporta grafo completo a JSON
├── brain-import.sh          Mergea export de otro dev en Neo4j (agrega solo lo que falta)
├── backup.sh                Backup y restore de volúmenes
│
│── Documentación ────────────────────────────────────────────────────────────
├── GUIA-PRACTICA.md         Wizard de instalación paso a paso (todos los SO)
├── ONBOARDING.md            Guía del sistema de niveles para el equipo
├── CONTEXT.md               Estado actual, decisiones tomadas y próximos pasos
└── README.md                Este archivo
```

---

## Setup inicial

### En un solo comando (recomendado)

**Windows (CMD)**
```bat
setup.bat
```

**Windows (PowerShell)**
```powershell
.\setup.ps1
```

**Linux / macOS**
```bash
chmod +x setup.sh && ./setup.sh
```

El instalador orquesta todo automáticamente: hace backup de la configuración existente
del usuario, verifica prerequisitos, levanta Neo4j, inicializa la base de datos,
carga la arquitectura KLAP BYSF, registra el MCP y copia el CLAUDE.md al perfil.

Ver [`GUIA-PRACTICA.md`](GUIA-PRACTICA.md) para el wizard completo.

### Desinstalar

**Windows (CMD)**
```bat
setup.bat --uninstall
```

**Linux / macOS**
```bash
./setup.sh --uninstall
```

El desinstalador detiene Neo4j y elimina sus datos, y restaura la configuración de
Claude Code (`~/.claude.json`, `settings.json`, skills, `CLAUDE.md`) al estado exacto
previo a la instalación usando el backup creado por el instalador.

### Paso a paso (manual / Linux / macOS)

| Paso | Windows CMD | Windows PowerShell | Linux / macOS |
|------|-------------|-------------------|---------------|
| 1. Levantar Neo4j | `brain.bat up` | `.\brain.ps1 up` | `docker compose up -d` |
| 2. Inicializar DB *(1 vez)* | `init-brain.bat` | `.\init-brain.ps1` | `./init-brain.sh` |
| 3. Registrar MCP *(1 vez)* | `brain.bat mcp` | `.\brain.ps1 mcp` | ver abajo |
| 4. Cargar arquitectura *(1 vez)* | `enrich-brain.bat` | `.\enrich-brain.bat` | `./enrich-brain.sh` |
| 5. Copiar CLAUDE.md *(1 vez)* | `copy CLAUDE.md %USERPROFILE%\.claude\CLAUDE.md` | `Copy-Item CLAUDE.md "$env:USERPROFILE\.claude\CLAUDE.md"` | `cp CLAUDE.md ~/.claude/CLAUDE.md` |

**Registro manual del MCP (Linux / macOS):**
```bash
claude mcp add-json "team-brain" \
  '{"command":"npx","args":["-y","@knowall-ai/mcp-neo4j-agent-memory"],"env":{"NEO4J_URI":"bolt://localhost:7687","NEO4J_USERNAME":"neo4j","NEO4J_PASSWORD":"team-brain-2025","NEO4J_DATABASE":"neo4j"}}' \
  --scope user
```

---

## Uso diario

| Acción | Windows CMD | Windows PowerShell | Linux / macOS |
|--------|-------------|-------------------|---------------|
| Levantar | `brain.bat up` | `.\brain.ps1 up` | `docker compose up -d` |
| Detener | `brain.bat down` | `.\brain.ps1 down` | `docker compose down` |
| Estado | `brain.bat status` | `.\brain.ps1 status` | `docker compose ps` |
| Logs | `brain.bat logs` | `.\brain.ps1 logs` | `docker compose logs -f neo4j` |
| Browser | `brain.bat browser` | `.\brain.ps1 browser` | `open http://localhost:7474` |
| Exportar grafo | `brain.bat export [file]` | — | `./brain-export.sh [file]` |
| Importar/mergear grafo | `brain.bat import <file>` | — | `./brain-import.sh <file>` |

---

## Backup y restore

**Windows (CMD)**
```bat
backup.bat                                    :: crear backup
backup.bat list                               :: listar backups
backup.bat restore backups\neo4j-backup-XXX.tar.gz  :: restaurar
```

**Windows (PowerShell)**
```powershell
.\backup.ps1
.\backup.ps1 -Action list
.\backup.ps1 -Action restore -File "backups\neo4j-backup-XXX.tar.gz"
```

**Linux / macOS**
```bash
./backup.sh
./backup.sh list
./backup.sh restore backups/neo4j-backup-XXX.tar.gz
```

Los backups se guardan en `backups/neo4j-backup-YYYYMMDD_HHMMSS.tar.gz`.

---

## Verificar en Neo4j Browser

URL: `http://localhost:7474` — Usuario: `neo4j` / Password: `team-brain-2025`

```cypher
-- Ver todos los nodos
MATCH (n:Entity) RETURN n

-- Resumen por tipo
MATCH (n:Entity) RETURN n.entityType as tipo, count(n) as total ORDER BY total DESC

-- Ver relaciones
MATCH (n)-[r]->(m) RETURN n.name, type(r), m.name LIMIT 50
```

---

## Onboarding de otro dev

El servidor Neo4j corre en **una sola máquina** (quien tiene Docker).
Cada dev en su propia máquina solo necesita:

1. Instalar Node.js >= 18 y Claude Code
2. Registrar el MCP apuntando a la IP del host (no `localhost`)
3. Copiar el `CLAUDE.md`

---

## Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| `No se esperaba REQUIRE` en init-brain | Community Edition + escaping CMD antiguo | Usar `init-brain.bat` actual (escribe JSON en archivos temporales) |
| `@jovanhsu/mcp-neo4j-memory-server` 404 | Paquete eliminado de npm | Usar `@knowall-ai/mcp-neo4j-agent-memory` |
| MCP aparece como `local` scope | Se registró sin `--scope user` | `claude mcp remove "team-brain"` y re-registrar |
| Neo4j en loop de restart | Volúmenes corruptos en primer arranque | `docker compose down -v` y volver a levantar |
| `Invalid value for password` | Password muy corta o igual a `neo4j` | Usar password de al menos 8 caracteres distinta a `neo4j` |
| MCP `disconnected` | Neo4j no está corriendo | `brain.bat up` / `docker compose up -d` |
| `HTTP 401` en init | Password incorrecta | Verificar que coincida en `docker-compose.yml` e `init-brain.*` |

---

## Stack del equipo

- **Java 21** + **Spring Boot 3.5.11** + **Spring Cloud 2025.0.0** + **Gradle 9**
- Microservicios event-driven: **Kafka** (AWS MSK) + **PostgreSQL Aurora**
- 14 microservicios — estándar documentado en `ARQUITECTURA_REFERENCIA.md`

---

*Team Brain KLAP BYSF · README.md · 2026-04-11*
