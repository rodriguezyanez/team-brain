# Team Brain — Guía Práctica de Instalación

> **Punto de partida:** Docker Desktop abierto y corriendo. Nada más.
> **Tiempo estimado:** 5 minutos.

---

## Descripción del ecosistema

### ¿Qué es Team Brain?

Un sistema de memoria compartida para el equipo de desarrollo KLAP BYSF.
Combina **Neo4j** (grafo de conocimiento), **Claude Code** (asistente IA) y **MCP**
(protocolo de conexión entre ambos). El objetivo es que Claude recuerde el contexto
del equipo entre sesiones y entre devs: decisiones técnicas, patrones, convenciones
y arquitectura.

```
Dev 1 (Claude Code)
Dev 2 (Claude Code)  ──→  MCP team-brain  ──→  Neo4j (bolt://localhost:7687)
Dev 3 (Claude Code)
```

---

### Archivos del proyecto

#### Infraestructura

| Archivo | Descripción |
|---------|-------------|
| `docker-compose.yml` | Define el contenedor Neo4j 5.18 Community. Expone el puerto `7474` (browser) y `7687` (bolt). Los datos persisten en 4 volúmenes Docker — **no se pierden** con `docker compose down`. |

#### Scripts de gestión

| Archivo | SO | Descripción |
|---------|----|-------------|
| `brain.bat` | Windows CMD | Comando principal de operaciones diarias. Acepta: `up`, `down`, `restart`, `status`, `logs`, `browser`, `mcp`. |
| `brain.ps1` | Windows PowerShell | Versión PowerShell de `brain.bat`. Mismos comandos, con colores y mejor manejo de errores. |

#### Scripts de inicialización (ejecutar UNA sola vez)

| Archivo | SO | Descripción |
|---------|----|-------------|
| `init-brain.bat` | Windows CMD | Inicializa Neo4j: crea constraints, índices y los 4 nodos base (`Team`, `Architecture`, `Decisions`, `Conventions`). Espera automáticamente a que Neo4j esté listo. |
| `init-brain.ps1` | Windows PowerShell | Versión PowerShell de `init-brain.bat`. Detecta edición Community vs Enterprise y ajusta la base de datos (`neo4j` vs `memory`) automáticamente. |
| `init-brain.sh` | Linux / macOS | Misma lógica que `init-brain.ps1`: detecta la edición y usa la DB correspondiente. |
| `enrich-brain.bat` | Windows CMD | Carga la arquitectura de referencia KLAP BYSF completa en Neo4j: stack tecnológico, capas, estructura de paquetes, configuración Kafka, persistencia, convenciones de naming/logging, 21 reglas DO, 13 reglas DON'T y 8 templates de código. Ejecutar después de `init-brain`. |

#### Scripts de backup

| Archivo | SO | Descripción |
|---------|----|-------------|
| `backup.bat` | Windows CMD | Backup y restore de los volúmenes de Neo4j usando un contenedor Alpine temporal. Uso: `backup.bat` (crear), `backup.bat list`, `backup.bat restore <archivo>`. |
| `backup.ps1` | Windows PowerShell | Versión PowerShell de `backup.bat`. Misma funcionalidad con mejor output (muestra tamaño en MB). |
| `backup.sh` | Linux / macOS | Versión bash del backup. |

#### Configuración de Claude Code

| Archivo | Descripción |
|---------|-------------|
| `CLAUDE.md` | System prompt del equipo. Define el protocolo de memoria (consultar Neo4j al inicio de cada sesión), los 4 niveles de asistencia (`initial`, `junior`, `dev`, `senior`), JavaDoc obligatorio, reglas de cuándo guardar en memoria y el flujo de onboarding. Copiar a `~/.claude/CLAUDE.md` (Linux/macOS) o `%USERPROFILE%\.claude\CLAUDE.md` (Windows) para aplicar globalmente. |

#### Documentación

| Archivo | Descripción |
|---------|-------------|
| `CONTEXT.md` | Estado actual del proyecto, arquitectura del ecosistema, comandos de referencia rápida y problemas conocidos con sus soluciones. Punto de entrada para retomar el trabajo entre sesiones. |
| `GUIA-PRACTICA.md` | Este archivo. Wizard de instalación paso a paso desde cero. |
| `ONBOARDING.md` | Guía del sistema de niveles para compartir con nuevos integrantes del equipo. |
| `README.md` | Documentación general del proyecto. |

---

## PASO 1 — Levantar Neo4j

Abre una terminal en la carpeta `team-brain/` y ejecuta:

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

**Salida esperada:**
```
Levantando Team Brain...
[OK] Neo4j corriendo.
     Browser: http://localhost:7474
     Bolt:    bolt://localhost:7687
```

> Neo4j tarda ~20 segundos en estar completamente listo.
> Si ves errores, verifica que Docker Desktop esté iniciado.

---

➡️ **SIGUIENTE PASO:** verifica que el contenedor esté listo:

**Windows (CMD)**
```bat
brain.bat status
```

**Windows (PowerShell)**
```powershell
.\brain.ps1 status
```

**Linux / macOS**
```bash
docker compose ps
```

Espera hasta ver `healthy` o `running` en la columna STATUS.
Cuando lo veas, continúa al **PASO 2**.

---

## PASO 2 — Inicializar la base de datos

Ejecuta **una sola vez**:

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
chmod +x init-brain.sh
./init-brain.sh
```

Este script:
- Espera a que Neo4j esté listo (hasta 30 intentos)
- Detecta si es Community (usa `neo4j`) o Enterprise (crea y usa `memory`)
- Crea constraints e índices
- Carga los nodos base: `Team`, `Architecture`, `Decisions`, `Conventions`

**Salida esperada (al final):**
```
[OK] Neo4j listo.
  -> Constraint Entity.name unico... [OK]
  -> Indice Entity.entityType... [OK]
  -> Indice Observation.content... [OK]
  -> Indice Entity.createdAt... [OK]
  -> Nodo Team... [OK]
  -> Nodo Architecture... [OK]
  -> Nodo Decisions... [OK]
  -> Nodo Conventions... [OK]
[OK] Team Brain inicializado correctamente
```

> ⚠️ `HTTP 401` → la password no coincide con `docker-compose.yml`.
> ⚠️ `HTTP 0` repetidamente → Neo4j todavía no terminó de arrancar, espera unos segundos más.

---

➡️ **SIGUIENTE PASO:** continúa al **PASO 3**.

---

## PASO 3 — Registrar el MCP en Claude Code

**Windows (CMD)**
```bat
brain.bat mcp
```

**Windows (PowerShell)**
```powershell
.\brain.ps1 mcp
```

**Linux / macOS**
```bash
claude mcp add-json "team-brain" \
  '{"command":"npx","args":["-y","@knowall-ai/mcp-neo4j-agent-memory"],"env":{"NEO4J_URI":"bolt://localhost:7687","NEO4J_USERNAME":"neo4j","NEO4J_PASSWORD":"team-brain-2025","NEO4J_DATABASE":"neo4j"}}' \
  --scope user
```

Este comando registra el paquete `@knowall-ai/mcp-neo4j-agent-memory` con scope `user`
(disponible en todos los proyectos de Claude Code en tu máquina).

**Salida esperada:**
```
[OK] MCP registrado. Verificando...
team-brain   npx  (connected)
```

> Si ves `disconnected`:
> - Verifica que Neo4j esté corriendo
> - Verifica que Node.js >= 18 esté instalado: `node --version`
>
> ⚠️ Si ya tenías registrado un MCP `team-brain` con el paquete antiguo
> `@jovanhsu/mcp-neo4j-memory-server` (eliminado de npm), reemplázalo:
> ```
> claude mcp remove "team-brain"
> ```
> Luego vuelve a ejecutar este paso.

---

➡️ **SIGUIENTE PASO:** continúa al **PASO 4**.

---

## PASO 4 — Cargar la arquitectura de referencia KLAP BYSF

**Windows (CMD)**
```bat
enrich-brain.bat
```

**Windows (PowerShell)**
```powershell
# enrich-brain.bat también funciona desde PowerShell
.\enrich-brain.bat
```

**Linux / macOS**
```bash
chmod +x enrich-brain.sh
./enrich-brain.sh
```

Este script carga **20+ nodos** con toda la arquitectura del equipo:
estándares, reglas DO/DON'T, templates de código, convenciones.

**Salida esperada (al final):**
```
[1/8] Nodo raiz del estandar...
  -> Nodo Standard KLAP BYSF... [OK]
[2/8] Stack tecnologico...
  ...
[8/8] Templates de codigo (estructuras)...
  ...
[OK] Arquitectura de referencia cargada
```

> ⚠️ `[ERROR] Neo4j no disponible` → ejecuta primero el paso 1.

---

➡️ **SIGUIENTE PASO:** continúa al **PASO 5**.

---

## PASO 5 — Verificar en Neo4j Browser

**Windows (CMD)**
```bat
brain.bat browser
```

**Windows (PowerShell)**
```powershell
.\brain.ps1 browser
```

**Linux / macOS**
```bash
open http://localhost:7474        # macOS
xdg-open http://localhost:7474   # Linux
```

**Credenciales:**
- Usuario: `neo4j`
- Password: `team-brain-2025`

Corre esta query para ver todo el grafo:

```cypher
MATCH (n:Entity) RETURN n
```

Deberías ver **~24 nodos** conectados en el grafo.

Para ver el resumen por tipo:

```cypher
MATCH (n:Entity) RETURN n.entityType as tipo, count(n) as total ORDER BY total DESC
```

---

➡️ **SIGUIENTE PASO:** continúa al **PASO 6**.

---

## PASO 6 — Activar el CLAUDE.md global

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

> Si ya tienes un `CLAUDE.md` global y no quieres sobreescribirlo, agrega el
> contenido al final del existente.

---

➡️ **SIGUIENTE PASO:** continúa al **PASO 7**.

---

## PASO 7 — Probar que todo funciona

Abre Claude Code en cualquier proyecto y escribe:

```
¿Qué sabes del equipo?
```

**Respuesta esperada:**
```
🧠 Consultando memoria del equipo...
[Claude consulta Neo4j y describe el equipo, stack y arquitectura]
```

Si Claude responde sin consultar el grafo, verifica:
1. Neo4j está corriendo (`brain.bat status` / `docker compose ps`)
2. `claude mcp list` muestra `team-brain (connected)`
3. El `CLAUDE.md` está en `~/.claude/CLAUDE.md` o `%USERPROFILE%\.claude\CLAUDE.md`

---

## ✅ Setup completo

| Paso | Windows CMD | Windows PS | Linux/macOS | Solo 1 vez |
|------|-------------|------------|-------------|-----------|
| 1 | `brain.bat up` | `.\brain.ps1 up` | `docker compose up -d` | No |
| 2 | `init-brain.bat` | `.\init-brain.ps1` | `./init-brain.sh` | Sí |
| 3 | `brain.bat mcp` | `.\brain.ps1 mcp` | `claude mcp add-json ...` | Sí |
| 4 | `enrich-brain.bat` | `.\enrich-brain.bat` | `./enrich-brain.sh` | Sí |
| 5 | `brain.bat browser` | `.\brain.ps1 browser` | `open http://localhost:7474` | No |
| 6 | `copy CLAUDE.md` | `Copy-Item CLAUDE.md` | `cp CLAUDE.md` | Sí |
| 7 | Prueba en Claude Code | | | — |

---

## Uso diario (después del setup)

**Windows (CMD)**
```bat
brain.bat up       ← al empezar el día
brain.bat down     ← al terminar (datos persisten)
brain.bat status   ← para verificar si está corriendo
```

**Windows (PowerShell)**
```powershell
.\brain.ps1 up
.\brain.ps1 down
.\brain.ps1 status
```

**Linux / macOS**
```bash
docker compose up -d
docker compose down
docker compose ps
```

---

## Onboarding de otro dev

Los pasos **2, 4 y 6** son por máquina, una sola vez.
El **PASO 3** (registrar MCP) cada dev lo ejecuta en su propia máquina.
Los pasos **2 y 4** solo los ejecuta quien hostea Neo4j (la máquina con Docker).

Si otro dev se conecta a un Neo4j ya inicializado (en red local o VPN), solo necesita:
- **PASO 3** — registrar el MCP apuntando a la IP del host en lugar de `localhost`
- **PASO 6** — copiar el CLAUDE.md

---

*Team Brain KLAP BYSF · GUIA-PRACTICA.md · 2026-04-11*
