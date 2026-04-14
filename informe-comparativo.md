# Informe comparativo: Team Brain KLAP BYSF vs gentle-ai

**Fecha**: Abril 2026
**Referencia**: https://github.com/Gentleman-Programming/gentle-ai

---

## Resumen ejecutivo

`gentle-ai` y Team Brain resuelven el mismo problema desde ángulos opuestos.
`gentle-ai` es un instalador de ecosistema **genérico y horizontal** — sirve para
cualquier dev, cualquier stack, cualquier agente. Team Brain es un ecosistema
**especializado y vertical** — construido específicamente para el equipo KLAP BYSF,
su arquitectura de microservicios, sus convenciones y su contexto de negocio.

Esta diferencia de enfoque hace que ambos se complementen más de lo que compiten.

---

## Comparación por componente

### Memoria persistente

| Aspecto | Team Brain (KLAP BYSF) | gentle-ai (Engram) |
|---------|----------------------|-------------------|
| Motor | Neo4j + grafo de conocimiento | SQLite + FTS5 (búsqueda full-text) |
| Estructura | Grafo de entidades con relaciones tipadas | Observaciones por topic key (key-value semántico) |
| Búsqueda | Cypher queries + MCP tools | Full-text search + topic keys |
| Visualización | Neo4j Browser (interfaz web con grafo visual) | TUI integrado + exportación a Obsidian con graph view |
| Persistencia | Docker con volúmenes nombrados | Binario local con archivo SQLite |
| Compartición | Multi-dev: todos apuntan al mismo Neo4j | Individual por dev (sin modo compartido nativo) |
| Costo de setup | Docker + MCP server npm | Un binario Go, sin dependencias |
| Contexto cargado | Arquitectura KLAP BYSF, reglas DO/DON'T, templates | Memoria de sesiones del dev individual |

**Ventaja Team Brain**: el grafo compartido entre devs es una diferencia fundamental.
Engram es por diseño individual — cada dev tiene su propia memoria. Team Brain tiene
una memoria colectiva del equipo que persiste entre personas.

**Ventaja gentle-ai/Engram**: SQLite es mucho más simple de operar que Neo4j. Sin
Docker, sin configuración de red, sin password. El dev lo instala y funciona
en segundos.

---

### Skills / templates de código

| Aspecto | Team Brain (KLAP BYSF) | gentle-ai (Skills) |
|---------|----------------------|-------------------|
| Formato | Nodos en Neo4j + CLAUDE.md | Archivos `.md` en `~/.claude/skills/` |
| Descubrimiento | `memory_search` vía MCP | `skill-registry.md` local + Engram |
| Contenido | Templates Java/Spring Boot KLAP BYSF | React 19, Next.js 15, TypeScript, Tailwind 4, Go, Angular, etc. |
| Actualización | Manual (re-ejecutar `enrich-brain.bat`) | `gentle-ai sync` actualiza automáticamente |
| Sub-agentes | No implementado | Sub-agentes SDD cargan skills relevantes automáticamente según el proyecto |
| Comunidad | Privado (estándares internos del equipo) | Repositorio público con voting comunitario |

**Ventaja Team Brain**: los skills están contextualizados con el negocio de KLAP BYSF.
No son patterns genéricos — son los patterns exactos que usa el equipo, con las
decisiones tomadas y sus justificaciones.

**Ventaja gentle-ai**: el sistema de skills es más sofisticado. Los sub-agentes los
descubren automáticamente, hay un registro con metadatos, y se pueden actualizar
con un solo comando.

---

### Flujo de desarrollo (SDD vs ninguno)

| Aspecto | Team Brain (KLAP BYSF) | gentle-ai (SDD) |
|---------|----------------------|----------------|
| Workflow estructurado | No implementado | SDD de 9 fases: explore → propose → spec → design → implement → verify |
| Planificación antes de codear | No | Sí — el agente planifica antes de escribir código |
| Sub-agentes especializados | No | Sí — cada fase tiene un sub-agente dedicado |
| Activación | N/A | Automática para features grandes, manual con "use sdd" |
| Multi-modelo | N/A | Sí — cada fase puede usar un modelo diferente (OpenCode) |

**Ventaja gentle-ai**: SDD es una diferencia cualitativa importante. En lugar de
"pedirle código al agente", el flujo obliga a planificar arquitectura, revisar
propuesta y aprobar spec antes de que se escriba una sola línea. Reduce deuda
técnica generada por IA.

---

### Persona y niveles de asistencia

| Aspecto | Team Brain (KLAP BYSF) | gentle-ai (Persona) |
|---------|----------------------|-------------------|
| Niveles | `initial`, `junior`, `dev`, `senior` | Persona `gentleman` (mentor que enseña) |
| Activación | Manual (`nivel: junior`) o detección automática | Global al instalar |
| Onboarding | Flujo guiado de 8 etapas con ejercicios | No estructurado, depende de la persona |
| JavaDoc | Obligatorio, con formato estándar del equipo | No especificado |
| Contexto del negocio | Sí — conoce KLAP BYSF, liquidación SVBO | No — genérico |

**Ventaja Team Brain**: el sistema de niveles adaptativo con onboarding estructurado
es más sofisticado que una persona fija. Especialmente valioso para equipos con
devs de distintos niveles de experiencia.

---

### Instalación y distribución

| Aspecto | Team Brain (KLAP BYSF) | gentle-ai |
|---------|----------------------|-----------|
| Instalación | Manual: scripts bat/sh + docker-compose | Un comando: `gentle-ai install` |
| SO soportados | Linux, macOS, Windows (bat + ps1) | Linux, macOS, Windows (Scoop) |
| Agentes soportados | Claude Code | Claude Code, OpenCode, Cursor, Windsurf, Gemini CLI |
| Actualizaciones | Manual (re-ejecutar scripts) | `gentle-ai sync` |
| Rollback | `backup.bat restore` | Snapshot automático antes de instalar |
| Dry-run | No | Sí (`--install --dry-run`) |

**Ventaja gentle-ai**: la experiencia de instalación es superior por un margen
considerable. Un comando, detección automática de agentes instalados, rollback
automático y preview de cambios.

---

### Code review con IA

| Aspecto | Team Brain (KLAP BYSF) | gentle-ai (GGA) |
|---------|----------------------|----------------|
| Code review automático | No implementado | GGA (Guardian Angel AI) en cada commit |
| Integración git | No | Hook pre-commit / post-commit |
| Estándar de review | N/A | Basado en las skills instaladas |

**Ventaja gentle-ai**: GGA es una funcionalidad que Team Brain no tiene. El code
review automático en cada commit usando las convenciones del equipo es una capa
de control de calidad de alto valor.

---

### Documentación en tiempo real

| Aspecto | Team Brain (KLAP BYSF) | gentle-ai (Context7) |
|---------|----------------------|---------------------|
| Documentación de librerías | No | Context7 MCP: documentación actualizada de cualquier librería en el contexto |
| Actualizaciones | N/A | En tiempo real vía MCP |

**Ventaja gentle-ai**: Context7 resuelve un problema real — Claude Code a veces
genera código basado en versiones antiguas de librerías. Context7 inyecta la
documentación de la versión exacta que estás usando.

---

## Mapa de fortalezas

```
                    TEAM BRAIN          GENTLE-AI
                    ──────────          ─────────
Memoria colectiva       ██████              ██░░░░
Contexto de negocio     ██████              ░░░░░░
Niveles y onboarding    ██████              ████░░
Templates de dominio    ██████              ████░░
Grafo de conocimiento   ██████              ████░░
─────────────────────────────────────────────────
Instalación/UX          ██░░░░              ██████
Workflow SDD            ░░░░░░              ██████
Code review IA          ░░░░░░              ██████
Docs en tiempo real     ░░░░░░              ██████
Multi-agente            ░░░░░░              ██████
Actualización auto      ░░░░░░              ██████
```

---

## Sugerencias para enriquecer Team Brain

Las siguientes mejoras están ordenadas de mayor a menor impacto estimado:

### 1. Implementar SDD (Spec-Driven Development)

**Por qué**: Es la diferencia más significativa. El flujo actual de Team Brain
permite que el dev le pida código directamente al agente sin planificar. SDD
obliga a que el agente explore el codebase, proponga un enfoque, lo valide
contigo y solo entonces implemente.

**Cómo adaptarlo para KLAP BYSF**: crear un `CLAUDE.md` con 5 fases simplificadas
adaptadas al contexto de microservicios:

```
Fase 1 - Explorar: leer el dominio afectado, consultar memoria del equipo
Fase 2 - Proponer: presentar enfoque de implementación con justificación
Fase 3 - Revisar: validar contra reglas DO/DON'T del equipo
Fase 4 - Implementar: código siguiendo los templates y convenciones
Fase 5 - Verificar: confirmar que los tests cubren 95%+ y JavaDoc está completo
```

Activación: `sdd: [descripción del feature]` en cualquier sesión de Claude Code.

---

### 2. Agregar GGA (Guardian Angel AI) adaptado al equipo

**Por qué**: Las reglas DO/DON'T del equipo existen pero hoy solo se consultan
cuando el dev genera código. No hay nada que audite los cambios antes de un commit.

**Cómo**: crear un hook `pre-commit` en git que ejecute una revisión automatizada
contra las reglas del equipo:

```bash
# .git/hooks/pre-commit
# Ejecutar: claude -p "Revisa este diff contra las reglas DO/DON'T del equipo KLAP BYSF.
# Verifica: JavaDoc en métodos nuevos, no JPA/Hibernate, no SQL hardcodeado,
# enable.metrics.push=false en configs Kafka, naming conventions.
# Diff: $(git diff --staged)"
```

---

### 3. Integrar Context7 para documentación de librerías

**Por qué**: Spring Boot 3.5.11, Spring Cloud 2025.0.0 y Resilience4j 2.2.0 son
versiones recientes. Claude Code puede generar código basado en APIs de versiones
anteriores.

**Cómo**: agregar Context7 al registro MCP junto a `team-brain`:

```cmd
claude mcp add-json "context7" "{\"command\":\"npx\",\"args\":[\"-y\",\"@upstash/context7-mcp\"]}"
```

Una vez instalado, al pedir código simplemente agregar `use context7` al prompt:

```
Genera un KafkaListener siguiendo el estándar del equipo. use context7
```

---

### 4. Crear un instalador `setup.bat` / `setup.ps1` unificado

**Por qué**: El onboarding actual requiere ejecutar 4-5 pasos manuales en orden.
Es fácil saltarse uno o ejecutarlos en el orden equivocado.

**Cómo**: un script que orqueste todo el setup de primer uso:

```bat
setup.bat
:: 1. Verifica Docker, Node, Claude Code
:: 2. Lee docker-compose.yml para obtener la password configurada
:: 3. Ejecuta brain.bat up
:: 4. Espera que Neo4j esté listo
:: 5. Ejecuta init-brain.bat
:: 6. Ejecuta enrich-brain.bat
:: 7. Registra el MCP con --scope user
:: 8. Copia CLAUDE.md a %USERPROFILE%\.claude\
:: 9. Imprime resumen del estado final
```

Equivalente a `gentle-ai install` para el ecosistema Team Brain.

---

### 5. Skill registry local (`.claude/skills/`)

**Por qué**: Los templates de código hoy viven en Neo4j, lo que requiere que el
MCP esté conectado para accederlos. Si Neo4j no está corriendo, el agente no
tiene acceso a los templates.

**Cómo**: además de Neo4j, exportar los templates como archivos Markdown en
`~/.claude/skills/`:

```
~/.claude/skills/
├── kafka-config.md      Template KafkaConfig con estructura y reglas
├── kafka-listener.md    Template Listener con circuit breaker
├── processor.md         Template Processor saga pattern
├── repository.md        Template Repository JdbcTemplate
├── webclient.md         Template WebClient con retry
├── exceptions.md        Template jerarquía de excepciones
└── testing.md           Template test con Mockito
```

El agente puede leer estos archivos incluso sin Neo4j corriendo. Son el fallback
local del conocimiento del equipo.

---

### 6. `gentle-ai sync` equivalente: `brain-update.bat`

**Por qué**: Cuando se actualice `ARQUITECTURA_REFERENCIA.md`, hoy no hay forma
sencilla de re-sincronizar Neo4j. Hay que re-ejecutar `enrich-brain.bat` completo,
que borra y recrea todos los nodos.

**Cómo**: un script que use `MERGE` en lugar de `CREATE`, de modo que solo
actualice los nodos que cambiaron sin borrar la memoria acumulada del equipo
(decisiones, bugs, etc.):

```bat
brain-update.bat
:: Actualiza solo los nodos del Standard (Stack, Kafka, Templates, DO/DONT)
:: Preserva: Decision, Fix, Pattern, Convention, Developer, Service
```

---

### 7. Exportación a Obsidian (inspirado en Engram)

**Por qué**: Engram tiene una feature muy valorada: exportar el grafo de memoria
a Obsidian para visualización y navegación. Neo4j ya tiene grafo visual en el
browser, pero Obsidian es más accesible para el equipo completo.

**Cómo**: un script que exporte los nodos de Neo4j a archivos Markdown con links
`[[wikilink]]` para que funcionen en Obsidian:

```
vault/
├── Standard KLAP BYSF.md      [[Kafka Config Standard]] [[Persistencia Standard]]
├── Kafka Config Standard.md   [[Kafka Topics Standard]]
├── Reglas DO.md               (21 reglas como lista)
└── ...
```

---

## Conclusión

Team Brain tiene algo que gentle-ai no puede tener por diseño: **conocimiento
específico del dominio de negocio**. El grafo de KLAP BYSF con sus reglas DO/DON'T,
sus templates Java, sus decisiones arquitectónicas y su historia acumulada es un
activo que se construyó sesión a sesión y no puede reemplazarse con un instalador
genérico.

Lo que gentle-ai tiene y Team Brain debería incorporar son las mejoras de
**experiencia operacional**: instalación en un comando, sincronización automática,
code review en cada commit, y el flujo SDD que evita que la IA genere código sin
planificación previa.

La hoja de ruta recomendada es incorporar las sugerencias 1 (SDD simplificado),
3 (Context7) y 4 (instalador unificado) como prioridad inmediata, ya que son las
de mayor impacto con menor esfuerzo de implementación.

---

*Informe generado en base al README, docs y código fuente de gentle-ai v0.1.1*
*Comparado contra Team Brain KLAP BYSF v1.0 — Abril 2026*
