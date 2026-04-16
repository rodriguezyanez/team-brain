# Team Brain — Guía Práctica

> **Punto de partida:** Docker Desktop abierto y corriendo. Nada más.
> **Tiempo estimado:** 5 minutos con el instalador unificado.

---

## ¿Qué es Team Brain?

Un ecosistema de memoria compartida para el equipo KLAP BYSF. Conecta a todos los devs
a un grafo de conocimiento Neo4j a través de Claude Code + MCP. El asistente recuerda
decisiones técnicas, patrones, convenciones y arquitectura entre sesiones y entre devs.
Es **agnóstico al proyecto**: sirve para cualquier microservicio del ecosistema KLAP BYSF.

```
Dev 1 (Claude Code)
Dev 2 (Claude Code)  ──→  MCP team-brain  ──→  Neo4j (grafo de conocimiento)
Dev 3 (Claude Code)
```

---

## Setup en un comando (recomendado)

El instalador unificado hace todo automáticamente:

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

El instalador ejecuta en orden:
1. Hace backup de la configuración actual del usuario (`.claude.json`, `settings.json`, skills, `CLAUDE.md`) en `~/.claude/team-brain-backup/`
2. Verifica prerequisitos (Docker, Node.js >= 18, Claude Code, curl)
3. Levanta Neo4j
4. Inicializa la base de datos
5. Carga la arquitectura de referencia KLAP BYSF
6. Registra el MCP `team-brain` en Claude Code (`--scope user`)
7. Registra el MCP `context7` (documentación en tiempo real)
8. Instala los skill files en `~/.claude/skills/`
9. Copia `CLAUDE.md` al perfil del usuario

> Si prefieres control paso a paso, sigue la sección **Setup manual** más abajo.

---

## Desinstalar

Revierte la instalación y restaura la configuración del usuario al estado previo:

**Windows (CMD)**
```bat
setup.bat --uninstall
```

**Linux / macOS**
```bash
./setup.sh --uninstall
```

El desinstalador:
1. Pide confirmación antes de proceder
2. Detiene Neo4j y elimina sus datos (`docker compose down -v`)
3. Restaura `.claude.json`, `settings.json`, skills y `CLAUDE.md` desde el backup creado durante la instalación
4. Elimina el directorio de backup `~/.claude/team-brain-backup/`

> **Sin backup previo:** si el backup no existe (ej. instalación manual), el desinstalador elimina solo las entradas de Team Brain sin tocar el resto de la configuración.

> **Docker, Node.js y Claude Code no se desinstalan** — son prerequisitos del usuario, no del ecosistema.

---

## Archivos del ecosistema

### Infraestructura

| Archivo | Descripción |
|---------|-------------|
| `docker-compose.yml` | Neo4j 5.18 Community. Puertos `7474` (browser) y `7687` (bolt). 4 volúmenes persistentes — los datos **no se pierden** con `docker compose down`. |

### Scripts de gestión diaria

| Archivo | SO | Descripción |
|---------|----|-------------|
| `brain.bat` | Windows CMD | Operaciones diarias: `up`, `down`, `restart`, `status`, `logs`, `browser`, `mcp`, `update`, `sync`, `export`, `import` |
| `brain.ps1` | Windows PowerShell | Ídem con colores y mejor manejo de errores |

### Instaladores y setup

| Archivo | SO | Descripción |
|---------|----|-------------|
| `setup.bat` | Windows CMD | Instalador unificado — setup completo en un comando |
| `setup.ps1` | Windows PowerShell | Ídem PowerShell |
| `setup.sh` | Linux / macOS | Ídem bash |
| `init-brain.bat` | Windows CMD | Inicializa Neo4j (ejecutar UNA sola vez). Detecta Community vs Enterprise. |
| `init-brain.ps1` | Windows PowerShell | Ídem |
| `init-brain.sh` | Linux / macOS | Ídem |
| `enrich-brain.bat` | Windows CMD | Carga la arquitectura de referencia KLAP BYSF completa (20+ nodos) |
| `enrich-brain.sh` | Linux / macOS | Ídem |

### Actualización incremental

| Archivo | SO | Descripción |
|---------|----|-------------|
| `brain-update.bat` | Windows CMD | Actualiza los nodos del Standard en Neo4j usando `MERGE`. **No borra** la memoria acumulada del equipo (Decision, Fix, Pattern, Developer, Service, etc.) |
| `brain-update.ps1` | Windows PowerShell | Ídem |
| `brain-update.sh` | Linux / macOS | Ídem |

### Consolidación de grafos entre devs

| Archivo | SO | Descripción |
|---------|----|-------------|
| `brain-export.ps1` | Windows PowerShell | Exporta el grafo completo (entidades + relaciones) a un archivo JSON. Invocado vía `brain.bat export`. |
| `brain-import.ps1` | Windows PowerShell | Importa y mergea un JSON exportado por otro dev. Agrega solo lo que falta — nunca sobreescribe. Invocado vía `brain.bat import <archivo>`. |
| `brain-export.sh` | Linux / macOS | Ídem. Invocado directamente: `./brain-export.sh [archivo.json]`. Requiere `curl` y `jq`. |
| `brain-import.sh` | Linux / macOS | Ídem. Invocado directamente: `./brain-import.sh <archivo.json>`. Requiere `curl` y `jq`. |

### MCPs adicionales

| Archivo | SO | Descripción |
|---------|----|-------------|
| `install-context7.bat` | Windows CMD | Registra Context7 MCP en Claude Code (`--scope user`). Provee docs en tiempo real de Spring Boot 3.5.11, Kafka, Resilience4j, WebClient. |
| `install-context7.ps1` | Windows PowerShell | Ídem |
| `install-context7.sh` | Linux / macOS | Ídem |

### Skill registry local

| Archivo | SO | Descripción |
|---------|----|-------------|
| `install-skills.bat` | Windows CMD | Copia los skill files a `%USERPROFILE%\.claude\skills\`. Fallback cuando Neo4j no está disponible. |
| `install-skills.ps1` | Windows PowerShell | Ídem |
| `install-skills.sh` | Linux / macOS | Copia a `~/.claude/skills/` |

### Guardian Angel (code review pre-commit)

| Archivo | SO | Descripción |
|---------|----|-------------|
| `install-hooks.bat` | Windows CMD | Instala el hook pre-commit en un proyecto. Cada commit Java/Kotlin es revisado por Claude contra las reglas DO/DON'T. |
| `install-hooks.ps1` | Windows PowerShell | Ídem. Acepta `-ProjectDir C:\ruta\proyecto` |
| `install-hooks.sh` | Linux / macOS | Ídem. Acepta `/ruta/al/proyecto` como argumento |
| `hooks/pre-commit.sh` | Bash | El hook en sí. Se copia a `.git/hooks/pre-commit` del proyecto destino. |
| `hooks/review-prompt.md` | — | Las 10 reglas que Claude verifica en cada commit |

### Exportación a Obsidian

| Archivo | SO | Descripción |
|---------|----|-------------|
| `export-obsidian.bat` | Windows CMD | Exporta el grafo Neo4j completo a archivos `.md` con `[[wikilinks]]` en `./vault/` |
| `export-obsidian.ps1` | Windows PowerShell | Ídem — implementación principal |
| `export-obsidian.sh` | Linux / macOS | Ídem (requiere Python3) |

### Backup

| Archivo | SO | Descripción |
|---------|----|-------------|
| `backup.bat` | Windows CMD | Backup/restore de volúmenes Docker. Uso: `backup.bat`, `backup.bat list`, `backup.bat restore <archivo>` |
| `backup.ps1` | Windows PowerShell | Ídem |
| `backup.sh` | Linux / macOS | Ídem |

### Configuración de Claude Code

| Archivo | Descripción |
|---------|-------------|
| `CLAUDE.md` | System prompt del equipo. Define el protocolo de selección de proyecto, JavaDoc obligatorio, flujo SDD y reglas de memoria. Asume siempre perfil senior. |

### Documentación

| Archivo | Descripción |
|---------|-------------|
| `CONTEXT.md` | Estado del proyecto, arquitectura del ecosistema y comandos de referencia rápida |
| `ONBOARDING.md` | Guía del ecosistema para nuevos integrantes (perfil senior) |
| `GUIA-PRACTICA.md` | Este archivo |
| `README.md` | Documentación general |
| `ENRICHMENT-PLAN.md` | Plan de enriquecimiento del ecosistema (7/7 fases completadas) |

---

## Setup manual paso a paso

Seguir esta sección si preferís control total, si `setup.bat` falla en algún paso,
o si estás conectándote a un Neo4j ya instalado en otra máquina.

---

### PASO 1 — Levantar Neo4j

**Windows (CMD)**
```bat
brain.bat up
```

**Windows (PowerShell)**
```powershell
.\brain.ps1 up
```

**Linux / macOS**
```bash
docker compose up -d
```

Verificar que el contenedor esté listo:

```bat
brain.bat status
```

Esperar hasta ver `healthy` o `running`. Neo4j tarda ~20 segundos en arrancar.

---

### PASO 2 — Inicializar la base de datos *(una sola vez)*

**Windows (CMD)**
```bat
init-brain.bat
```

**Windows (PowerShell)**
```powershell
.\init-brain.ps1
```

**Linux / macOS**
```bash
chmod +x init-brain.sh && ./init-brain.sh
```

Crea constraints, índices y los 4 nodos base. No volver a ejecutar.

> `HTTP 401` → la password no coincide con `docker-compose.yml`
> `HTTP 0` repetidamente → Neo4j todavía no terminó de arrancar

---

### PASO 3 — Registrar el MCP team-brain *(una sola vez por máquina)*

**Windows (CMD / PowerShell)**
```bat
brain.bat mcp
```

**Linux / macOS**
```bash
claude mcp add-json "team-brain" \
  '{"command":"npx","args":["-y","@knowall-ai/mcp-neo4j-agent-memory"],"env":{"NEO4J_URI":"bolt://localhost:7687","NEO4J_USERNAME":"neo4j","NEO4J_PASSWORD":"team-brain-2025","NEO4J_DATABASE":"neo4j"}}' \
  --scope user

claude mcp add-json "context7" \
  '{"command":"npx","args":["-y","@upstash/context7-mcp"]}' \
  --scope user
```

> `brain.bat mcp` registra tanto `team-brain` como `context7` en un solo comando.

Verificar:
```bat
claude mcp list
```

Debe mostrar `team-brain (connected)` y `context7 (connected)`.

> Si ves `disconnected` en team-brain: Neo4j no está corriendo. Ejecutar `brain.bat up`.

---

### PASO 4 — Cargar la arquitectura de referencia KLAP BYSF *(una sola vez)*

**Windows (CMD)**
```bat
enrich-brain.bat
```

**Linux / macOS**
```bash
chmod +x enrich-brain.sh && ./enrich-brain.sh
```

Carga 20+ nodos: stack, arquitectura, Kafka, persistencia, convenciones, 21 reglas DO,
13 reglas DON'T y 8 templates de código.

---

### PASO 5 — Instalar skill files locales *(una sola vez por máquina)*

```bat
install-skills.bat
```

```powershell
.\install-skills.ps1
```

```bash
chmod +x install-skills.sh && ./install-skills.sh
```

Los skills son el fallback local cuando Neo4j no está disponible. Se copian a
`%USERPROFILE%\.claude\skills\` (Windows) o `~/.claude/skills/` (Linux/macOS).

---

### PASO 6 — Activar el CLAUDE.md global *(una sola vez por máquina)*

**Windows (CMD)**
```bat
copy CLAUDE.md %USERPROFILE%\.claude\CLAUDE.md
```

**Windows (PowerShell)**
```powershell
Copy-Item CLAUDE.md "$env:USERPROFILE\.claude\CLAUDE.md"
```

**Linux / macOS**
```bash
cp CLAUDE.md ~/.claude/CLAUDE.md
```

---

### PASO 7 — Verificar en Neo4j Browser *(opcional)*

```bat
brain.bat browser
```

Credenciales: usuario `neo4j` / password `team-brain-2025`

```cypher
MATCH (n:Entity) RETURN n
```

Deberías ver ~24 nodos conectados.

---

### PASO 8 — Probar en Claude Code

Abre Claude Code en cualquier proyecto y escribe:

```
¿Qué sabes del equipo?
```

Claude debería responder consultando Neo4j y luego preguntar en qué proyecto vas a trabajar.

---

## Resumen de pasos *(con setup.bat es todo automático)*

| Paso | CMD | PowerShell | Linux/macOS | ¿Solo 1 vez? |
|------|-----|------------|-------------|-------------|
| 0b — Backup config usuario | *(automático en setup.bat)* | *(automático en setup.ps1)* | *(automático en setup.sh)* | Sí |
| 1 — Levantar Neo4j | `brain.bat up` | `.\brain.ps1 up` | `docker compose up -d` | No |
| 2 — Init DB | `init-brain.bat` | `.\init-brain.ps1` | `./init-brain.sh` | Sí |
| 3 — Registrar MCPs | `brain.bat mcp` | `.\brain.ps1 mcp` | ver arriba | Sí |
| 4 — Cargar arquitectura | `enrich-brain.bat` | `.\enrich-brain.bat` | `./enrich-brain.sh` | Sí |
| 5 — Instalar skills | `install-skills.bat` | `.\install-skills.ps1` | `./install-skills.sh` | Sí |
| 6 — Activar CLAUDE.md | `copy CLAUDE.md ...` | `Copy-Item ...` | `cp CLAUDE.md ...` | Sí |
| **Desinstalar** | `setup.bat --uninstall` | `.\setup.ps1 --uninstall` | `./setup.sh --uninstall` | — |

---

## Uso diario

```bat
brain.bat up                   ← levantar Neo4j al empezar el día
brain.bat down                 ← detener al terminar (datos persisten)
brain.bat status               ← verificar si está corriendo
brain.bat update               ← sincronizar arquitectura si cambió ARQUITECTURA_REFERENCIA.md
brain.bat sync                 ← sincronizar memorias pendientes locales con Neo4j
brain.bat export [file.json]   ← exportar grafo completo a JSON (para consolidar con master)
brain.bat import <file.json>   ← mergear export de otro dev en este Neo4j
```

---

## Cómo trabajar con un proyecto

Al abrir Claude Code, el asistente siempre pregunta primero:

> "¿En qué proyecto o microservicio vas a trabajar hoy?"

**Si el proyecto ya existe en Neo4j** → Claude carga su contexto (topics Kafka, tablas,
decisiones previas) y aplica el Standard KLAP BYSF.

**Si el proyecto es nuevo** → Claude propone usar SDD para explorarlo:

```
sdd: [descripción del proyecto]
```

La Fase 1 del SDD (Explorar) mapea el dominio completo y al finalizar registra
automáticamente el proyecto como nodo `Service` en Neo4j, disponible para todo el equipo.

---

## Herramientas adicionales

### Guardian Angel — Code review pre-commit

Instala el hook en cualquier proyecto del equipo para que Claude revise cada commit
Java/Kotlin contra las 10 reglas DO/DON'T antes de permitirlo:

```bat
install-hooks.bat C:\ruta\a\tu\proyecto
```

```powershell
.\install-hooks.ps1 -ProjectDir C:\ruta\a\tu\proyecto
```

```bash
./install-hooks.sh /ruta/a/tu/proyecto
```

Bypass para commits urgentes: `git commit --no-verify`

---

### Context7 — Documentación en tiempo real

Agrega `use context7` a cualquier prompt para obtener la documentación de la versión
exacta de las librerías del stack:

```
use context7, ¿cómo configuro un CircuitBreaker con Resilience4j 2.2.0?
use context7, ¿cómo funciona ErrorHandlingDeserializer en Spring Kafka?
```

---

### Exportar a Obsidian

Para visualizar el grafo completo sin abrir Neo4j Browser:

```bat
export-obsidian.bat
```

Genera `vault/` con un archivo `.md` por nodo y `[[wikilinks]]` entre ellos.
Abrir en Obsidian: **Archivo → Abrir vault → seleccionar `vault/`**.

---

### Consolidar grafos de varios devs en un master

Cada dev trabaja con su Neo4j local. Para consolidar toda la información en un único master:

**1. Cada dev exporta su grafo:**

Windows:
```bat
brain.bat export
:: genera: teambrain-export-<hostname>-<timestamp>.json
```

Linux / macOS:
```bash
./brain-export.sh
# genera: teambrain-export-<hostname>-<timestamp>.json
```

El nombre del archivo incluye el hostname y timestamp automáticamente.
Si querés nombrar el archivo manualmente:
```bat
brain.bat export mis-memorias.json     :: Windows
./brain-export.sh mis-memorias.json    :: Linux/macOS
```

**2. El dev comparte el archivo** (Slack, email, carpeta compartida, etc.) con el responsable del master.

**3. El responsable del master importa cada archivo:**

Windows:
```bat
brain.bat import teambrain-export-dev01-20260416-143022.json
```

Linux / macOS:
```bash
./brain-import.sh teambrain-export-dev01-20260416-143022.json
```

El import reporta en detalle qué se agregó:
```
[NEW]  DecisionXxx              ← entidad nueva
[UPD]  Standard KLAP BYSF (+2 obs)  ← observaciones nuevas agregadas
[NEW]  DevA -[CONOCE]-> DevB   ← relacion nueva

Entidades: 3 nuevas, 5 actualizadas, 47 sin cambios
Relaciones: 2 nuevas, 18 sin cambios
```

**Reglas de merge:**
- Entidad nueva → se crea completa
- Entidad existente → solo se agregan observaciones que no estén en el master; `entityType` del master se preserva
- Relaciones → MERGE por `(from, relationType, to)`, no duplica

---

### Memoria local cuando Neo4j no está disponible

Si Neo4j no está corriendo durante una sesión de trabajo, Claude guarda automáticamente las memorias en una cola local:

- **Windows:** `%USERPROFILE%\.claude\pending-memories.jsonl`
- **Linux/macOS:** `~/.claude/pending-memories.jsonl`

Cuando Neo4j vuelva a estar disponible, sincronizar la cola:

```bat
brain.bat sync
```

```powershell
.\brain.ps1 sync
```

```bash
./brain-sync.sh
```

El script procesa cada entrada, las empuja a Neo4j y limpia las que fueron exitosas. Las entradas fallidas se conservan en el archivo para el próximo intento.

---

### Actualizar el Standard

Cuando cambie `ARQUITECTURA_REFERENCIA.md`:

```bat
brain.bat update
```

Actualiza solo los nodos del Standard (Stack, Kafka, Templates, DO/DON'T).
**No toca** la memoria acumulada del equipo (Decision, Fix, Pattern, Developer, Service).

---

## Onboarding de otro dev

Los pasos **2, 4, 5 y 6** son por máquina, una sola vez.
El **PASO 3** (registrar MCPs) cada dev lo ejecuta en su propia máquina.

Si otro dev se conecta a un Neo4j ya inicializado (red local o VPN), solo necesita:
- **PASO 3** — registrar los MCPs apuntando a la IP del host en lugar de `localhost`
- **PASO 5** — instalar los skill files locales
- **PASO 6** — copiar el CLAUDE.md

Consultar `ONBOARDING.md` para el recorrido completo del ecosistema.

---

## Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| `No se esperaba REQUIRE` en init-brain | Community Edition + CMD antiguo | Usar `init-brain.bat` actual (escribe JSON en archivos temporales) |
| MCP `@jovanhsu/...` da 404 | Paquete eliminado de npm | Usar `@knowall-ai/mcp-neo4j-agent-memory` |
| MCP aparece como `local` scope | Registrado sin `--scope user` | `claude mcp remove "team-brain"` y re-registrar |
| Neo4j en loop de restart | Volúmenes corruptos en primer arranque | `docker compose down -v` y volver a levantar |
| `Invalid value for password` | Password muy corta o igual a `neo4j` | Usar password de al menos 8 caracteres |
| MCP `disconnected` | Neo4j no está corriendo | `brain.bat up` |
| `HTTP 401` | Password incorrecta | Verificar que coincida en `docker-compose.yml` |
| Guardian Angel no activa | Claude CLI no encontrado | `npm install -g @anthropic-ai/claude-code` |

---

*Team Brain KLAP BYSF · GUIA-PRACTICA.md · 2026-04-16*
