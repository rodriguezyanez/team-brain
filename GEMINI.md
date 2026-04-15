# GEMINI.md — Instrucciones del Proyecto Team Brain (KLAP BYSF)

Este archivo proporciona el contexto técnico y las directrices operativas para interactuar con el ecosistema **Team Brain**.

## Descripción del Proyecto
**Team Brain** es un sistema de memoria compartida diseñado para el equipo de desarrollo KLAP BYSF. Utiliza **Neo4j** como base de datos de grafos para almacenar el contexto del equipo (decisiones, patrones, arquitectura) y el Model Context Protocol (**MCP**) para conectar este conocimiento con asistentes de IA (Claude/Gemini).

### Componentes Clave
- **Neo4j (Docker):** Almacén persistente del grafo de conocimiento.
- **MCP `@knowall-ai/mcp-neo4j-agent-memory`:** Puente de comunicación entre el asistente y el grafo.
- **Protocolo SDD (Spec-Driven Development):** Flujo de 5 fases (Explorar, Proponer, Validar, Implementar, Verificar) para desarrollo estandarizado.
- **Skill Registry:** Fallback local de plantillas y reglas cuando la base de datos no está disponible.

---

## Directrices de Desarrollo (Estándar KLAP BYSF)

Cuando generes código o asistas en tareas técnicas para este equipo, debes seguir estas reglas innegociables:

### 1. Stack Tecnológico
- **Lenguaje:** Java 21.
- **Framework:** Spring Boot 3.5.11 / Spring Cloud 2025.0.0.
- **Persistencia:** `JdbcTemplate` con queries en constantes (`ConstantsQuery`). **PROHIBIDO usar JPA/Hibernate.**
- **Mensajería:** Kafka (AWS MSK).
- **Testing:** JUnit 5 + Mockito + AssertJ. Cobertura mínima: **95%**.

### 2. Convenciones de Código
- **JavaDoc Obligatorio:** En todos los métodos públicos, describiendo el *objetivo* del método.
- **Naming:**
    - Servicios: `XxxService` / `XxxServiceImpl`.
    - Repositorios: `XxxRepository`.
    - Kafka: `XxxKafkaListener` / `XxxKafkaConfig`.
    - Procesadores (Sagas): `XxxProcessor` / `XxxProcessorImpl`.
- **Kafka:** Configurar siempre `max.poll.records = 1` y `enable.metrics.push = false`.

### 3. Niveles de Asistencia
El sistema soporta 4 niveles que deben respetarse en las respuestas:
- `initial`: Explicaciones desde cero, analogías, código completo línea por línea.
- `junior`: Explica el "por qué" de las decisiones y patrones del equipo.
- `dev` (default): Asume conocimiento del stack, se enfoca en contexto de negocio.
- `senior`: Conciso, directo, solo menciona lo no obvio.

---

## Comandos Operativos

### Gestión del Ecosistema (Windows)
| Acción | Comando |
|--------|---------|
| Levantar Neo4j | `brain.bat up` |
| Estado del sistema | `brain.bat status` |
| Sincronizar Estándar | `brain.bat update` |
| Abrir Neo4j Browser | `brain.bat browser` |
| Backup del grafo | `backup.bat` |

### Flujo de Trabajo con Proyectos
1. **Inicio:** Preguntar siempre "¿En qué proyecto o microservicio vas a trabajar hoy?".
2. **Memoria:** Usar `memory_search` para cargar el contexto del proyecto desde Neo4j.
3. **Nuevos Proyectos:** Si no existe, activar flujo SDD escribiendo `sdd: [descripción]`.

---

## Uso de Herramientas Especiales

- **Context7:** Agrega `use context7` al prompt para consultar documentación técnica en tiempo real de las librerías del stack.
- **Guardian Angel:** Hook pre-commit que revisa el cumplimiento de las 10 reglas críticas del equipo.
- **Obsidian Export:** Ejecuta `export-obsidian.bat` para visualizar el grafo de conocimiento en Obsidian (`./vault`).

---

## Archivos de Referencia Críticos
- `CLAUDE.md`: System prompt maestro del equipo.
- `skills/*.md`: Plantillas de código por componente (Kafka, WebClient, Repository, etc.).
- `CONTEXT.md`: Estado actual y decisiones arquitectónicas recientes.
- `GUIA-PRACTICA.md`: Manual detallado de instalación y troubleshooting.

---
*GEMINI.md generado para Team Brain · KLAP BYSF · Abril 2026*
