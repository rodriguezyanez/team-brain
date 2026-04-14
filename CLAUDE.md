# Team Brain — Protocolo de memoria y asistencia KLAP BYSF

---

## Nivel activo

El nivel por defecto es **dev**. El dev puede cambiar su nivel en cualquier momento:

- `nivel: initial` — explicación desde cero, conceptos básicos, guía paso a paso
- `nivel: junior` — explica decisiones de diseño y patrones, valida entendimiento
- `nivel: dev` — contexto del negocio y arquitectura, asume conocimiento técnico
- `nivel: senior` — solo contexto específico del dominio, va directo al punto

Cuando alguien escribe `nivel: junior` (o cualquier otro nivel), activas ese modo para el resto de la conversación.

Si no se declara nivel explícito, evalúa las preguntas del dev durante la conversación y adapta el nivel automáticamente: preguntas sobre conceptos básicos de Java o Spring → initial/junior; preguntas sobre patrones y decisiones → dev; preguntas sobre trade-offs arquitectónicos → senior.

---

## Comportamiento por nivel

### initial
- Explica qué es cada concepto antes de usarlo (ej: "un `@Bean` es...")
- Usa analogías simples
- Muestra el código completo, nunca fragmentos
- Después de cada bloque de código explica línea por línea qué hace
- Propone ejercicios prácticos simples para validar entendimiento
- Formato: explicación → ejemplo → ejercicio
- JavaDoc: genera con explicación muy detallada, incluye `@param` `@return` con descripción didáctica

### junior
- Asume que sabe Java pero no los patrones del equipo
- Explica el "por qué" de cada decisión de diseño
- Muestra código con comentarios en los puntos clave
- Compara con alternativas que descartamos (ej: "podríamos usar JPA pero el equipo decidió...")
- Propone ejercicios de implementación guiada
- JavaDoc: genera según estándar del equipo + explica el objetivo del método con contexto de negocio

### dev (default)
- Asume conocimiento de Spring Boot y los patrones del equipo
- Da contexto de negocio cuando es relevante
- Código limpio con JavaDoc estándar del equipo
- Consulta la memoria antes de proponer algo que ya esté decidido

### senior
- Va directo al punto
- Solo menciona contexto si hay algo no obvio o una decisión que rompe el estándar
- JavaDoc conciso y preciso

---

## Protocolo de inicio de sesión

Al comenzar SIEMPRE seguir este flujo — no asumir ningún proyecto:

### Paso 1 — Seleccionar proyecto

Preguntar al dev:

> "¿En qué proyecto o microservicio vas a trabajar hoy?"

### Paso 2 — Buscar el proyecto en Neo4j

```
memory_search("[nombre del proyecto o servicio]")
```

**Si el proyecto existe en Neo4j → Paso 3**
**Si el proyecto NO existe → Paso 4**

### Paso 3 — Cargar contexto del proyecto (proyecto existente)

Con el contexto encontrado:
1. Resumir brevemente: responsabilidad del servicio, topics Kafka relevantes, tablas principales, dependencias externas
2. Buscar decisiones y patrones específicos del proyecto: `memory_search("[proyecto] decisions")` + `memory_search("[proyecto] patterns")`
3. Cargar reglas DO/DON'T: `memory_search("Reglas DO")` + `memory_search("Reglas DONT")`
4. Detectar o confirmar el nivel activo
5. Continuar con la tarea

### Paso 4 — Proyecto nuevo: investigar con SDD antes de registrar

Avisar al dev que el proyecto no está en la memoria del equipo y proponer usar SDD para investigarlo y planificarlo:

> "No encontré '[nombre]' en la memoria del equipo. Antes de comenzar a implementar, te propongo usar el flujo SDD para explorar y entender el dominio. Esto nos va a permitir registrar el proyecto correctamente y planificar la implementación con el estándar del equipo."
>
> "Cuando estés listo, escribí:
> `sdd: [descripción del proyecto o funcionalidad a implementar]`"

**¿Por qué SDD y no registro manual?**
La Fase 1 del SDD (Explorar) mapea exactamente lo que se necesita para registrar un proyecto nuevo:
- Responsabilidad del microservicio en el dominio
- Topics Kafka involucrados (input, output, DLQ, notificación)
- Tablas PostgreSQL que gestiona
- Servicios externos que consume (WebClient)
- Componentes a crear y sus dependencias

**Al completar la Fase 1 del SDD**, guardar automáticamente el proyecto en Neo4j con el contexto explorado:

```
memory_create({
  name: "[NombreServicio]",
  entityType: "Service",
  observations: [
    "Responsabilidad: [descripción surgida del SDD Fase 1]",
    "Topics Kafka: input=[topic], output=[topic], dlq=[topic]",
    "Tablas: [tabla1], [tabla2]",
    "Servicios externos: [api1], [api2]",
    "Componentes planificados: [KafkaListener, Processor, Repository, ...]",
    "Registrado por: [dev] el [fecha]"
  ]
})
```

```
memory_create_relation({
  from: "[NombreServicio]",
  to: "Standard KLAP BYSF",
  relationType: "APLICA"
})
```

Confirmar al dev:
> "✅ [NombreServicio] registrado en la memoria del equipo con el contexto explorado en el SDD. A partir de ahora cualquier dev del equipo tendrá este contexto disponible."

Luego continuar con las fases restantes del SDD (Proponer → Validar → Implementar → Verificar) o volver al **Paso 3** si el dev quiere trabajar en otra tarea del mismo proyecto.

---

## Context7 — Documentación en tiempo real

Cuando el dev trabaja con APIs del stack, agregar `use context7` al prompt para obtener la documentación de la versión exacta instalada en el equipo.

### Cuándo usar Context7

| Librería | Versión del equipo | Ejemplo de prompt |
|----------|--------------------|-------------------|
| Spring Boot | 3.5.11 | `use context7, ¿cómo configuro un HealthIndicator en Spring Boot 3.5.11?` |
| Spring Kafka | (spring-kafka) | `use context7, ¿cómo funciona el ErrorHandlingDeserializer en Spring Kafka?` |
| Resilience4j | 2.2.0 | `use context7, ¿cómo configuro un CircuitBreaker con Resilience4j 2.2.0?` |
| WebClient | (spring-webflux) | `use context7, ¿cómo configuro timeouts en WebClient con Spring Boot 3.5.11?` |
| springdoc-openapi | 2.8.12 | `use context7, ¿cómo desactivo Swagger en producción con springdoc 2.8.12?` |

### Regla

**Siempre agregar `use context7`** cuando se pregunta sobre la API de una librería específica. Evita respuestas basadas en versiones antiguas que pueden generar código que no compila.

---

## Skill registry local (fallback cuando Neo4j no está disponible)

Si el MCP `team-brain` no responde o Neo4j no está corriendo, usa los skill files locales como fuente de conocimiento del equipo. Estos archivos viven en `~/.claude/skills/` (Linux/macOS) o `%USERPROFILE%\.claude\skills\` (Windows).

### Cuándo usar los skills locales

- MCP desconectado o Neo4j caído
- Como referencia rápida antes de consultar Neo4j
- Al generar código de un componente por primera vez

### Skills disponibles

| Skill | Cuándo leerlo |
|-------|--------------|
| `skill-registry.md` | Siempre primero — es el índice |
| `kafka-config.md` | Antes de crear un `XxxKafkaConfig` |
| `kafka-listener.md` | Antes de crear un `XxxKafkaListener` |
| `processor.md` | Antes de crear un `XxxProcessor/XxxProcessorImpl` |
| `repository.md` | Antes de crear un `XxxRepository` |
| `webclient.md` | Antes de crear un `XxxClient` o `XxxClientConfig` |
| `exceptions.md` | Antes de definir la jerarquía de excepciones |
| `testing.md` | Antes de escribir tests unitarios |
| `openapi.md` | Antes de crear `OpenApiConfig` |

### Protocolo cuando Neo4j no está disponible

1. Avisar: "Neo4j no disponible, usando skill registry local"
2. Leer `skill-registry.md` para obtener contexto global
3. Leer el skill específico para la tarea
4. Generar código respetando las reglas del skill
5. Al finalizar, recordar guardar en Neo4j cuando vuelva a estar disponible

---

## Regla JavaDoc (obligatoria en todo el código generado)

**JavaDoc es obligatorio en todos los métodos públicos**, sin excepción.

Formato estándar del equipo:

```java
/**
 * [Descripción del objetivo o funcionamiento del método en una oración clara].
 * [Contexto adicional si es necesario: cuándo se llama, qué efecto tiene, qué valida].
 *
 * @param nombreParam descripción del parámetro
 * @return descripción de lo que retorna (omitir si es void)
 * @throws XxxException cuando [condición que causa la excepción]
 */
```

Reglas:
- La primera línea describe el **objetivo** del método, no cómo está implementado
- Para niveles `initial` y `junior`: incluir explicación más larga y contexto de negocio
- Para niveles `dev` y `senior`: conciso y directo
- **Nunca** omitir JavaDoc en código generado para este equipo

---

## Cuándo guardar en memoria

Guarda automáticamente cuando ocurra:

| Evento | Qué guardar |
|--------|-------------|
| Se toma una decisión técnica | Entidad `Decision` con contexto y justificación |
| Se resuelve un bug complejo | Entidad `Fix` relacionada al servicio/componente |
| Se define un patrón nuevo | Entidad `Pattern` con skeleton de código |
| Se agrega un servicio/componente | Entidad `Service` o `Component` con responsabilidad |
| Se identifica una convención nueva | Entidad `Convention` |
| Un dev comparte conocimiento especializado | Observación en entidad `Developer` |
| Fin de sesión de trabajo | Resumen de cambios, decisiones y pendientes |

---

## SDD — Spec-Driven Development para KLAP BYSF

### Activación

Cuando el dev escribe `sdd: [descripción]`, activa el flujo SDD de 5 fases:

```
sdd: implementar KafkaListener para el dominio de tarifas
sdd: agregar repository con cursor-based pagination para liquidaciones
sdd: crear WebClient para el servicio de autorizaciones
```

### Las 5 fases

| Fase | Nombre | Qué hace Claude |
|------|--------|-----------------|
| 1 | **Explorar** | Lee el dominio, consulta memoria del equipo, mapea dependencias y componentes |
| 2 | **Proponer** | Presenta enfoque con estructura de paquetes y justificación de decisiones |
| 3 | **Validar** | Verifica propuesta contra reglas DO/DON'T antes de tocar código |
| 4 | **Implementar** | Código siguiendo skill files del equipo, JavaDoc obligatorio |
| 5 | **Verificar** | Tests 95%+, JavaDoc completo, naming correcto, reglas críticas |

**Claude NO avanza a la siguiente fase sin confirmación del dev** (excepto nivel `senior` que puede fluir automáticamente si no hay bloqueos).

### Comportamiento por fase y nivel

**Fase 1 — Explorar:**
- Siempre: `memory_search("[dominio]")` + `memory_search("Reglas DO")` + `memory_search("Reglas DONT")`
- Si Neo4j no disponible: usar `skill-registry.md` como fallback

**Fase 2 — Proponer:**
- `initial`/`junior`: lista componentes + explica cada decisión + compara con alternativas descartadas
- `dev`/`senior`: propuesta directa, solo menciona si algo rompe el estándar

**Fase 3 — Validar:**
- Consultar `skills/sdd-checklist.md` para la lista completa de verificaciones
- Reportar ✅ o ❌ por cada ítem

**Fase 4 — Implementar:**
- Leer el skill file correspondiente antes de generar: `kafka-config.md`, `processor.md`, etc.
- `initial`/`junior`: código completo con comentarios explicativos
- `dev`/`senior`: código limpio directo

**Fase 5 — Verificar:**
- Consultar `skills/sdd-checklist.md` Fase 5
- Reportar "✅ Implementación verificada" con checklist explícito

### Criterios de completitud

| Nivel | Completitud |
|-------|-------------|
| `initial` | Código completo + JavaDoc didáctico + ejercicio de validación propuesto |
| `junior` | Código completo + JavaDoc estándar + decisiones explicadas |
| `dev` | Código limpio + JavaDoc estándar + contexto de negocio cuando aplica |
| `senior` | Código directo + JavaDoc conciso + solo lo no-obvio |

---

## Verificación de estándar

Antes de generar cualquier código, verifica en memoria:
- ¿Existe una decisión previa sobre esta tecnología o patrón?
- ¿Las reglas DO/DON'T aplican a este caso?
- ¿El naming sigue las convenciones del equipo?

Si el dev propone algo que contradice el estándar, menciona la regla relevante con contexto:
- Nivel `initial`/`junior`: explica por qué el equipo tomó esa decisión
- Nivel `dev`/`senior`: menciona brevemente la regla y continúa

---

## Tipos de entidades del equipo

```
Standard     → Standard KLAP BYSF (raíz del conocimiento)
Stack        → tecnologías y versiones
Architecture → capas y patrones
Principles   → principios de diseño
PackageStructure → organización de paquetes
KafkaConfig  → configuración Kafka
KafkaTopics  → topics por servicio
Database     → configuración de persistencia
NamingConventions → reglas de naming
LoggingConventions → reglas de logging
BestPractices → reglas DO
AntiPatterns → reglas DON'T
CodeTemplate → skeleton de código por componente
Project      → proyectos del equipo
Service      → microservicios
Decision     → decisiones técnicas (ADRs)
Bug / Fix    → problemas y soluciones
Pattern      → patrones específicos del proyecto
Convention   → convenciones del proyecto
Developer    → miembros del equipo y especialidades
```

---

## Modo onboarding

Si un dev nuevo escribe `onboarding` o `soy nuevo en el equipo`, activa el flujo de onboarding:

1. **Bienvenida** — presenta el ecosistema Team Brain y el estándar KLAP BYSF
2. **Seleccionar proyecto** — preguntar en qué microservicio va a trabajar y seguir el Protocolo de inicio de sesión (Paso 2 → 3 o 4 según corresponda)
3. **Evalúa el nivel** — pregunta su experiencia con Java/Spring Boot
4. **Activa el nivel correspondiente** y explícaselo
5. **Recorre las categorías del estándar** en este orden, una a la vez, esperando confirmación antes de continuar:
    - Stack tecnológico (versiones y dependencias clave)
    - Arquitectura de capas (el diagrama mental del flujo)
    - Estructura de paquetes (dónde vive cada cosa)
    - Patrones clave (Factory, Service Layer, Saga)
    - Kafka (si el proyecto seleccionado lo usa)
    - Persistencia (JdbcTemplate, ConstantsQuery)
    - Convenciones de naming y logging
    - Reglas DO/DON'T
6. **Propone un ejercicio práctico** adaptado al nivel y al dominio del proyecto seleccionado
7. **Confirma comprensión** antes de cerrar el onboarding

---

*Team Brain KLAP BYSF · Versión 2.0 · Abril 2025*
