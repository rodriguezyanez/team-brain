# Skill: SDD para Microservicios KLAP BYSF

## Activación

El dev escribe:
```
sdd: [descripción de lo que quiere construir]
```

Ejemplo: `sdd: nuevo KafkaListener para procesar liquidaciones de sucursal`

Al activarse, Claude ejecuta las 5 fases en orden. No avanza a la siguiente fase sin completar la anterior. Consulta `sdd-checklist.md` al final de cada fase para verificar completitud.

---

## Las 5 Fases

### Fase 1 — Explorar

**Objetivo:** entender el dominio antes de proponer nada.

**Acciones:**
1. Identificar el microservicio involucrado y su responsabilidad principal
2. Consultar la memoria del equipo:
   - `memory_search "[dominio del feature]"`
   - `memory_search "Reglas DO"`
   - `memory_search "Reglas DONT"`
   - Si Neo4j no está disponible: leer `skill-registry.md` como fallback
3. Mapear dependencias externas:
   - ¿Qué topics Kafka consume? ¿Qué topics produce? ¿Tiene DLQ? ¿Topic de notificación?
   - ¿Qué tablas PostgreSQL toca?
   - ¿Qué servicios externos consume vía WebClient?
4. Identificar componentes afectados o a crear:
   - KafkaListener nuevo o modificado
   - Processor nuevo o modificado
   - Repository nuevo o modificado
   - Client (WebClient) nuevo o modificado
   - DTOs, entidades, mappers

**Output obligatorio:** resumen de 5-10 líneas con:
- Microservicio y responsabilidad
- Topics Kafka involucrados (input / output / DLQ / notificación)
- Tablas PostgreSQL involucradas
- Servicios externos consumidos
- Componentes a crear/modificar

---

### Fase 2 — Proponer

**Objetivo:** presentar el enfoque antes de tocar código.

**Acciones:**
1. Proponer la estructura de implementación con justificación arquitectónica
2. Listar cada componente a crear/modificar con su responsabilidad exacta
3. Mostrar la estructura de paquetes propuesta (`global/` vs paquete de dominio)
4. Identificar decisiones de diseño no triviales:
   - Nivel `initial`/`junior`: comparar con alternativas descartadas, explicar el por qué del equipo
   - Nivel `dev`/`senior`: mencionar solo si la decisión rompe el estándar o es no-obvia
5. Verificar que la propuesta no contradice decisiones previas en memoria del equipo

**Output obligatorio:** propuesta en markdown con:
```
## Propuesta de implementación
### Componentes
- XxxKafkaListener — responsabilidad
- XxxProcessor / XxxProcessorImpl — responsabilidad
- XxxRepository / XxxRepositoryImpl — responsabilidad
- XxxClient — responsabilidad (si aplica)

### Estructura de paquetes
com.klap.bysf.[servicio]/
  global/
    kafka/
    config/
  [dominio]/
    listener/
    processor/
    repository/
    client/
    dto/

### Decisiones de diseño
- [decisión]: [justificación]
```

---

### Fase 3 — Validar

**Objetivo:** verificar la propuesta contra el estándar del equipo antes de implementar.

**Checklist de validación:**

| Regla | Verificación |
|-------|-------------|
| Persistencia | ¿Usa JdbcTemplate? No JPA |
| Kafka config | ¿KafkaConfig extiende la clase base? No duplica lógica |
| Métricas | ¿`enable.metrics.push=false` en configuración Kafka? |
| Consumo | ¿`max.poll.records=1` en todos los consumers? |
| Deserialización | ¿`ErrorHandlingDeserializer` como wrapper? |
| Envío Kafka | ¿Sincrónico (`.get()`) en dominio financiero? |
| SQL | ¿Queries en `ConstantsQuery`? No hardcodeado |
| Paginación | ¿Cursor-based para tablas con >500 registros? |
| Naming | ¿XxxService/Impl, XxxProcessor/Impl, XxxKafkaListener, XxxRepository/Impl? |
| Paquetes | ¿`global/` para infraestructura, paquete de dominio para lógica? |
| JavaDoc | ¿Todos los métodos públicos tendrán JavaDoc? |

**Output:**
- `✅ Propuesta validada` — continúa a Fase 4
- Lista de correcciones necesarias — corregir antes de continuar

---

### Fase 4 — Implementar

**Objetivo:** generar el código siguiendo el estándar del equipo.

**Reglas de implementación:**
1. Usar el skill file correspondiente como referencia para cada componente:
   - `kafka-listener.md` → KafkaListener
   - `processor.md` → Processor / ProcessorImpl
   - `repository.md` → Repository / RepositoryImpl
   - `webclient.md` → XxxClient
   - `exceptions.md` → manejo de errores
   - `kafka-config.md` → KafkaConfig
2. Seguir el template exacto del skill — no inventar estructura nueva
3. JavaDoc obligatorio en todos los métodos públicos (ver formato en CLAUDE.md)
4. Logging con `idProceso` + `codigoSucursal` en cada log relevante
5. Manejo de errores diferenciado:
   - Error determinista (validación, negocio) → enviar a DLQ manualmente
   - Error de infraestructura → re-throw para que Kafka reintente

**Ajuste por nivel del dev:**

| Nivel | Código generado |
|-------|----------------|
| `initial` | Código completo, comentarios en puntos clave, JavaDoc didáctico con contexto de negocio |
| `junior` | Código completo, comentarios en decisiones de diseño, JavaDoc estándar del equipo |
| `dev` | Código limpio, JavaDoc estándar, contexto de negocio cuando aplica |
| `senior` | Código directo, JavaDoc conciso, solo lo no-obvio mencionado |

---

### Fase 5 — Verificar

**Objetivo:** confirmar que la implementación cumple todos los criterios del equipo.

**Verificaciones obligatorias:**

**Tests:**
- Cobertura >= 95% (JaCoCo)
- Tests siguen patrón AAA (Arrange-Act-Assert)
- `MockWebServer` para tests de XxxClient
- Tests de Processor cubren: flujo exitoso, error determinista, error de infraestructura

**Código:**
- Todos los métodos públicos tienen JavaDoc
- `enable.metrics.push=false` presente
- `max.poll.records=1` presente
- SQL en `ConstantsQuery` (no hardcodeado)
- Naming validado contra convenciones del equipo
- No hay valores hardcodeados que deberían estar en configuración

**Output:**
```
✅ Implementación verificada

Checklist confirmado:
- [x] Tests >= 95% cobertura
- [x] JavaDoc en todos los métodos públicos
- [x] enable.metrics.push=false
- [x] max.poll.records=1
- [x] SQL en ConstantsQuery
- [x] Naming correcto
```

Si algo no cumple: corregir antes de declarar completado.

---

## Criterios de completitud por nivel

| Nivel | Criterios |
|-------|-----------|
| `initial` | Código completo + JavaDoc didáctico + ejercicio de validación propuesto al final |
| `junior` | Código completo + JavaDoc estándar + explicación de decisiones de diseño |
| `dev` | Código limpio + JavaDoc estándar + contexto de negocio cuando aplica |
| `senior` | Código directo + JavaDoc conciso + solo lo no-obvio mencionado |

---

## Flujo rápido (referencia)

```
sdd: [descripción]
  │
  ├── Fase 1 — Explorar
  │     └── memory_search + mapeo de dominio → resumen 5-10 líneas
  │
  ├── Fase 2 — Proponer
  │     └── componentes + paquetes + decisiones de diseño
  │
  ├── Fase 3 — Validar
  │     └── checklist DO/DON'T → ✅ o lista de correcciones
  │
  ├── Fase 4 — Implementar
  │     └── código según skill files + JavaDoc + logging
  │
  └── Fase 5 — Verificar
        └── tests + naming + reglas críticas → ✅ listo para revisión
```

Skill file de referencia: `sdd-checklist.md`
Skills relacionados: `kafka-listener.md`, `processor.md`, `repository.md`, `webclient.md`, `exceptions.md`, `kafka-config.md`
