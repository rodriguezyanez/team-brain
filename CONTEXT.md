# Team Brain — Contexto del proyecto

Este archivo es el punto de entrada para Claude Code. Resume todo lo construido,
el estado actual y los próximos pasos. Léelo completo antes de continuar.

---

## Qué es Team Brain

Un ecosistema de memoria compartida para el equipo de desarrollo KLAP BYSF.
Combina Neo4j (grafo de conocimiento), Claude Code (asistente) y MCP (protocolo
de conexión entre ambos). El objetivo es que Claude recuerde el contexto del equipo
entre sesiones y entre devs: decisiones técnicas, patrones, convenciones, arquitectura.

---

## Arquitectura del ecosistema

```
Dev 1 (Claude Code)
Dev 2 (Claude Code)  ──→  MCP team-brain  ──→  Neo4j (bolt://localhost:7687)
Dev 3 (Claude Code)
```

- **Neo4j**: corre en Docker con volúmenes persistentes. Los datos sobreviven a reinicios.
- **MCP**: paquete `@knowall-ai/mcp-neo4j-agent-memory` registrado con scope `user` en Claude Code.
- **CLAUDE.md**: sistema prompt que activa protocolos de memoria, niveles de asistencia y JavaDoc obligatorio.

---

## Archivos del ecosistema

```
team-brain/
│
├── docker-compose.yml       Neo4j 5.18 Community con 4 volúmenes persistentes
│                            Puerto 7474 (browser) y 7687 (bolt)
│                            Password: team-brain-2025
│
├── CLAUDE.md                System prompt para Claude Code
│                            Instalar en: %USERPROFILE%\.claude\CLAUDE.md
│
├── ONBOARDING.md            Guía del sistema de niveles para compartir con el equipo
│
│── Linux / macOS ───────────────────────────────────────────────
├── setup.sh                 Instalador unificado: setup completo en un comando
├── init-brain.sh            Inicialización de Neo4j (ejecutar UNA vez)
├── backup.sh                Backup y restore de volúmenes
│
│── Windows ─────────────────────────────────────────────────────
├── setup.bat / setup.ps1    Instalador unificado: setup completo en un comando
├── brain.bat / brain.ps1    Comandos rápidos: up, down, status, logs, browser, mcp
├── init-brain.bat           Inicialización de Neo4j (ejecutar UNA vez)
├── init-brain.ps1           Versión PowerShell
├── backup.bat / backup.ps1  Backup y restore de volúmenes
├── enrich-brain.bat         Carga arquitectura de referencia KLAP BYSF en Neo4j
│
└── team-brain-guia-inicio.md  Guía completa Linux + Windows para el equipo
```

---

## Estado actual

### Neo4j
- Corriendo en Docker en la máquina local de Juan Pablo
- Base de datos: `neo4j` (Community Edition — no soporta múltiples DBs)
- Nodos base cargados por `init-brain.bat`: Team, Architecture, Decisions, Conventions

### MCP
- Paquete: `@knowall-ai/mcp-neo4j-agent-memory`
- Variables de entorno: `NEO4J_URI=bolt://localhost:7687`, `NEO4J_USERNAME=neo4j`, `NEO4J_PASSWORD=team-brain-2025`, `NEO4J_DATABASE=neo4j`
- Estado: **conectado** (`✓ Connected` en `claude mcp list`)
- Scope: user (disponible en todos los proyectos)
- **IMPORTANTE**: el MCP anterior `@jovanhsu/mcp-neo4j-memory-server` fue eliminado de npm. Usar siempre `@knowall-ai/mcp-neo4j-agent-memory`.

### enrich-brain.bat
- **Pendiente de ejecutar**
- Cargará la arquitectura de referencia KLAP BYSF en Neo4j (20+ nodos)
- Requiere Neo4j corriendo: `brain.bat up` primero

---

## Próximo paso inmediato

```bat
REM 1. Asegurarse de que Neo4j está corriendo
brain.bat up
brain.bat status

REM 2. Cargar la arquitectura de referencia
enrich-brain.bat

REM 3. Verificar en Neo4j Browser
REM    http://localhost:7474
REM    MATCH (n:Entity) RETURN n
```

---

## Estructura del grafo Neo4j (después de enrich-brain)

```
Standard KLAP BYSF (raíz)
├── Stack Tecnologico
│   └── Dependencias Principales
├── Arquitectura Capas
│   └── Principios Arquitectonicos
├── Estructura Paquetes
├── Kafka Config Standard
│   └── Kafka Topics Standard
├── Persistencia Standard
├── Convenciones Naming
├── Convenciones Logging
├── Reglas DO (21 reglas)
├── Reglas DONT (13 reglas)
└── Templates (8 nodos independientes)
    ├── Template KafkaConfig Dominio
    ├── Template KafkaListener
    ├── Template Processor
    ├── Template Repository
    ├── Template WebClient
    ├── Template Excepciones
    ├── Template Testing
    └── Template OpenAPI
```

---

## Sistema de niveles en CLAUDE.md

El CLAUDE.md activo implementa 4 niveles de asistencia. El dev activa el suyo escribiendo `nivel: X`:

| Nivel | Para quién | Comportamiento |
|-------|-----------|----------------|
| `initial` | Nuevo en Spring Boot | Explica conceptos desde cero, código completo línea por línea, ejercicios básicos |
| `junior` | Conoce Spring, nuevo en el equipo | Explica decisiones de diseño, compara alternativas descartadas, ejercicios guiados |
| `dev` | Conoce el stack y los patrones | Contexto de negocio cuando aplica, código limpio, nivel por defecto |
| `senior` | Dominio completo | Directo al punto, solo menciona lo no obvio |

Para activar onboarding automático: escribir `onboarding` en Claude Code.

---

## Reglas que aplican en todo el código generado

1. **JavaDoc obligatorio** en todos los métodos públicos — describe el objetivo del método
2. **Verificar reglas DO/DON'T** desde Neo4j antes de generar código
3. **Consultar memoria del equipo** al inicio de cada sesión (`memory_search`)

---

## Comandos de referencia rápida

```bat
:: Operaciones diarias
brain.bat up             :: levantar Neo4j
brain.bat down           :: detener
brain.bat status         :: ver estado
brain.bat logs           :: ver logs en vivo
brain.bat browser        :: abrir http://localhost:7474

:: Setup (ya ejecutados)
init-brain.bat           :: inicialización base (NO volver a ejecutar)
brain.bat mcp            :: registrar team-brain + Context7 en Claude Code

:: Actualización incremental (cuando cambia la arquitectura de referencia)
brain.bat update         :: sincronizar nodos Standard en Neo4j (preserva memoria)

:: Setup (pendiente)
enrich-brain.bat         :: carga completa arquitectura KLAP BYSF (primera vez)

:: Backup
backup.bat               :: crear backup
backup.bat list          :: listar backups
backup.bat restore <f>   :: restaurar

:: Verificar en Neo4j Browser
MATCH (n:Entity) RETURN n
MATCH (n:Entity) RETURN n.entityType as tipo, count(n) as total ORDER BY total DESC
MATCH (n)-[r]->(m) RETURN n.name, type(r), m.name LIMIT 50
```

## Flujo de actualización de arquitectura

Cuando el equipo actualiza `ARQUITECTURA_REFERENCIA.md`:

```bat
:: 1. Asegurar Neo4j corriendo
brain.bat up

:: 2. Sincronizar sin borrar memoria acumulada
brain.bat update
:: (o directamente: brain-update.bat)

:: ¿Qué preserva? → Decision, Fix, Pattern, Convention, Developer, Service, Bug
:: ¿Qué actualiza? → Standard, Stack, Architecture, Kafka, Templates, DO/DONT
```

---

## Problemas conocidos y soluciones

| Problema | Causa | Solución |
|----------|-------|----------|
| `No se esperaba REQUIRE` en init-brain | Community Edition + escaping CMD | Usar `init-brain.bat` v4 (usa archivos JSON temporales) |
| `@jovanhsu/mcp-neo4j-memory-server` 404 | Paquete eliminado de npm | Usar `@knowall-ai/mcp-neo4j-agent-memory` |
| MCP aparece como `local` scope | Se registró sin `--scope user` | `claude mcp remove "team-brain"` y re-registrar con `--scope user` |
| Neo4j en loop de restart | Volúmenes corruptos en primer arranque | `docker compose down -v` y volver a levantar |
| `Invalid value for password` | Password muy corta o igual a `neo4j` | Usar password de al menos 8 caracteres distinta a `neo4j` |

---

## Contexto del equipo

- **Equipo**: Liquidación SVBO — KLAP BYSF
- **Stack**: Java 21, Spring Boot 3.5.11, Spring Cloud 2025.0.0, Gradle 9
- **Arquitectura**: Microservicios event-driven con Kafka + PostgreSQL Aurora + AWS MSK
- **Microservicios**: 14 servicios, 90% cumple el estándar documentado en `ARQUITECTURA_REFERENCIA.md`
- **Documento base**: `ARQUITECTURA_REFERENCIA.md` v1.2.0 — fuente de verdad de los estándares

---

*Team Brain KLAP BYSF · CONTEXT.md v1.0 · Generado el 2026-04-11*
*Construido en conversación con Claude Sonnet 4.6 (Anthropic)*
