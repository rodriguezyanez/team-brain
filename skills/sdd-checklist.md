# Checklist SDD — Microservicios KLAP BYSF

Claude consulta este archivo automáticamente al avanzar entre fases del SDD.
Uso: marcar cada ítem antes de declarar la fase como completada.

---

## Fase 1 — Explorar

- [ ] Identifiqué el microservicio y su responsabilidad principal
- [ ] Consulté la memoria del equipo (`memory_search`) o el `skill-registry.md` como fallback
- [ ] Identifiqué los topics Kafka involucrados (input, output, DLQ, notificación)
- [ ] Identifiqué las tablas PostgreSQL involucradas
- [ ] Identifiqué los servicios externos que consume (WebClient)
- [ ] Listé los componentes a crear/modificar (KafkaListener, Processor, Repository, Client, etc.)
- [ ] Resumí el dominio en 5-10 líneas

---

## Fase 2 — Proponer

- [ ] Presenté la propuesta con estructura de paquetes explícita (`global/` vs dominio)
- [ ] Justifiqué cada decisión de diseño no trivial
- [ ] Listé todos los componentes con su responsabilidad
- [ ] Identifiqué las interfaces (XxxService, XxxProcessor) separadas de las implementaciones (XxxServiceImpl, XxxProcessorImpl)
- [ ] Verifiqué que la propuesta no contradice decisiones previas del equipo

---

## Fase 3 — Validar

- [ ] ¿Usa JdbcTemplate? (✅ correcto | ❌ usa JPA → corregir)
- [ ] ¿KafkaConfig extiende la clase base `KafkaConfig`? (no duplica lógica)
- [ ] ¿`enable.metrics.push=false` en la configuración Kafka?
- [ ] ¿`max.poll.records=1` en todos los consumers?
- [ ] ¿Naming correcto? (`XxxService`/`Impl`, `XxxProcessor`/`Impl`, `XxxKafkaListener`, `XxxRepository`/`Impl`)
- [ ] ¿Estructura de paquetes correcta? (`global/` para infraestructura, paquete de dominio para lógica)
- [ ] ¿SQL en `ConstantsQuery`? (no hardcodeado en el repositorio)
- [ ] ¿Paginación cursor-based para tablas con >500 registros?
- [ ] ¿`ErrorHandlingDeserializer` como wrapper en la configuración del consumer?
- [ ] ¿Envío Kafka sincrónico en dominio financiero (`.get()`)?

---

## Fase 4 — Implementar

- [ ] Usé el skill file correspondiente como referencia:
  - `kafka-listener.md` para KafkaListener
  - `processor.md` para Processor/ProcessorImpl
  - `repository.md` para Repository/RepositoryImpl
  - `webclient.md` para XxxClient
  - `exceptions.md` para manejo de errores
  - `kafka-config.md` para KafkaConfig
- [ ] JavaDoc en todos los métodos públicos (formato estándar del equipo)
- [ ] Logging incluye `idProceso` y `codigoSucursal` en cada log relevante
- [ ] Manejo de errores diferenciado:
  - Error determinista (validación, negocio) → envío manual a DLQ
  - Error de infraestructura → re-throw para reintento de Kafka
- [ ] Circuit breaker implementado en el listener (`AtomicInteger`, threshold=10, reset=60s)
- [ ] Cache con TTL en repositorio para datos de configuración (si aplica)

---

## Fase 5 — Verificar

- [ ] Cobertura de tests >= 95% (JaCoCo)
- [ ] Tests siguen patrón AAA (Arrange-Act-Assert)
- [ ] `MockWebServer` para tests de XxxClient
- [ ] Tests de Processor cubren: flujo exitoso, error determinista, error de infraestructura
- [ ] Todos los métodos públicos tienen JavaDoc
- [ ] `enable.metrics.push=false` presente en configuración
- [ ] `max.poll.records=1` presente en configuración del consumer
- [ ] SQL en `ConstantsQuery` (no hardcodeado)
- [ ] Naming validado contra convenciones del equipo
- [ ] No hay código hardcodeado que debería estar en configuración

---

## Resultado

- [ ] ✅ Todas las fases completadas — implementación lista para revisión
- [ ] ⚠️  Correcciones pendientes antes de declarar completado
