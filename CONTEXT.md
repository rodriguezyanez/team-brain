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
├── docker-compose.yml         Neo4j 5.18 Community — puertos 7474 y 7687
│                              4 volúmenes persistentes (datos sobreviven a reinicios)
│
├── CLAUDE.md                  System prompt del equipo para Claude Code
│                              Instalar en: %USERPROFILE%\.claude\CLAUDE.md (Windows)
│                                           ~/.claude/CLAUDE.md (Linux/macOS)
│
│── Documentación ─────────────────────────────────────────────────────
├── README.md                  Documentación general y referencia rápida
├── GUIA-PRACTICA.md           Wizard de instalación paso a paso (todos los SO)
├── ONBOARDING.md              Guía del ecosistema para nuevos integrantes
├── CONTEXT.md                 Este archivo — estado actual y referencia rápida
│
│── Windows ────────────────────────────────────────────────────────────
├── setup.bat                  Instalador/desinstalador unificado
│                              setup.bat --uninstall para desinstalar
├── brain.bat                  Operaciones diarias: up, down, status, logs, browser
├── init-brain.bat             Inicialización de Neo4j (ejecutar UNA vez)
├── enrich-brain.bat           Carga arquitectura de referencia KLAP BYSF
├── brain-update.bat           Sincronización incremental (preserva memoria acumulada)
├── install-skills.bat         Instala skill files en %USERPROFILE%\.claude\skills\
├── install-hooks.bat          Instala hook pre-commit Guardian Angel en un proyecto
├── brain-sync.bat             Sincroniza memorias locales pendientes con Neo4j
├── backup.bat                 Backup y restore de volúmenes Docker
├── export-obsidian.bat        Exporta el grafo Neo4j a archivos Markdown para Obsidian
│
│── Linux / macOS ──────────────────────────────────────────────────────
├── setup.sh                   Instalador/desinstalador unificado
│                              ./setup.sh --uninstall para desinstalar
├── init-brain.sh              Inicialización de Neo4j (ejecutar UNA vez)
├── enrich-brain.sh            Carga arquitectura de referencia KLAP BYSF
├── brain-update.sh            Sincronización incremental
├── install-skills.sh          Instala skill files en ~/.claude/skills/
├── install-hooks.sh           Instala hook pre-commit Guardian Angel en un proyecto
├── brain-sync.sh              Sincroniza memorias locales pendientes con Neo4j
├── backup.sh                  Backup y restore de volúmenes Docker
│
│── Skills locales (fallback cuando Neo4j no está disponible) ──────────
└── skills/                    Copiados a ~/.claude/skills/ por install-skills.*
    ├── skill-registry.md      Índice de skills — leer primero
    ├── kafka-config.md        Template KafkaConfig
    ├── kafka-listener.md      Template KafkaListener
    ├── processor.md           Template Processor/ProcessorImpl
    ├── repository.md          Template Repository con JdbcTemplate
    ├── webclient.md           Template WebClient
    ├── exceptions.md          Jerarquía de excepciones
    ├── testing.md             Tests unitarios (95%+ cobertura)
    ├── openapi.md             OpenApiConfig
    ├── sdd-microservice.md    Flujo SDD completo
    └── sdd-checklist.md       Checklist de verificación por fase SDD
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

### enrich-brain / skills / CLAUDE.md
- Arquitectura de referencia KLAP BYSF cargada en Neo4j (20+ nodos)
- Skill files instalados en `%USERPROFILE%\.claude\skills\`
- `CLAUDE.md` instalado en `%USERPROFILE%\.claude\CLAUDE.md`

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

## Comportamiento de Claude

El CLAUDE.md asume siempre perfil **senior**: directo al punto, sin explicaciones innecesarias, conocimiento profundo del stack y los patrones del equipo. No hay niveles configurables.

Protocolo de inicio de sesión:
1. Preguntar en qué proyecto o microservicio se va a trabajar
2. Buscar el proyecto en Neo4j (`memory_search`)
3. Si existe: cargar contexto + reglas DO/DON'T
4. Si no existe: proponer flujo SDD para explorarlo y registrarlo

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

:: Setup inicial (una sola vez por máquina)
setup.bat                :: instalador unificado — hace todo automáticamente
init-brain.bat           :: inicialización base (NO volver a ejecutar)
brain.bat mcp            :: registrar team-brain + Context7 en Claude Code
enrich-brain.bat         :: cargar arquitectura KLAP BYSF en Neo4j
install-skills.bat       :: instalar skill files en %USERPROFILE%\.claude\skills\

:: Desinstalar
setup.bat --uninstall    :: restaura config del usuario y elimina Neo4j + datos

:: Actualización incremental (cuando cambia la arquitectura de referencia)
brain.bat update         :: sincronizar nodos Standard en Neo4j (preserva memoria)

:: Memoria local pendiente
brain.bat sync           :: sincronizar memorias locales con Neo4j

:: Backup de volúmenes Docker
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
