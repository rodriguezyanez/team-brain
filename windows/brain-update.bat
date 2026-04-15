@echo off
REM =============================================================
REM brain-update.bat — Sincronizacion incremental de Neo4j
REM Actualiza nodos del Standard KLAP BYSF sin borrar memoria
REM Ejecutar cuando cambie ARQUITECTURA_REFERENCIA.md
REM Requiere: Neo4j corriendo (brain.bat up)
REM =============================================================

setlocal EnableDelayedExpansion

set NEO4J_HOST=localhost
set NEO4J_PORT=7474
set NEO4J_USER=neo4j
set NEO4J_PASS=team-brain-2025
set BASE_URL=http://%NEO4J_HOST%:%NEO4J_PORT%
set USE_DB=neo4j
set TMP=%TEMP%\neo4j_update.json

echo.
echo =====================================================
echo   Team Brain -- Sincronizacion incremental
echo   Standard KLAP BYSF (solo nodos de referencia)
echo   NUNCA borra Decision, Fix, Pattern, Developer...
echo =====================================================
echo.

REM ── Verificar curl ───────────────────────────────────────────
where curl >nul 2>&1
if %ERRORLEVEL% neq 0 (echo [ERROR] curl no encontrado. & exit /b 1)

REM ── Verificar Neo4j ──────────────────────────────────────────
echo {"statements":[{"statement":"RETURN 1"}]} > "%TMP%"
for /f "delims=" %%i in ('curl -s -o NUL -w "%%{http_code}" -u "%NEO4J_USER%:%NEO4J_PASS%" "%BASE_URL%/db/%USE_DB%/tx/commit" -H "Content-Type: application/json" -d @"%TMP%" 2^>NUL') do set STATUS=%%i
if not "%STATUS%"=="200" if not "%STATUS%"=="201" (
    echo [ERROR] Neo4j no disponible. Ejecuta: brain.bat up
    exit /b 1
)
echo [OK] Neo4j disponible.
echo.

REM =============================================================
echo [1/8] Actualizando nodo raiz Standard KLAP BYSF...
echo {"statements":[{"statement":"MERGE (s:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) SET s.version = '1.2.0', s.description = 'Arquitectura de referencia para microservicios KLAP BYSF', s.team = 'Liquidacion SVBO', s.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Standard KLAP BYSF (updatedAt)"

REM =============================================================
echo [2/8] Actualizando Stack Tecnologico...

echo {"statements":[{"statement":"MERGE (s:Entity {name: 'Stack Tecnologico', entityType: 'Stack'}) SET s.java = 'Java 21', s.gradle = 'Gradle 9.0.0', s.springBoot = 'Spring Boot 3.5.11', s.springCloud = 'Spring Cloud 2025.0.0', s.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Stack Tecnologico"

echo {"statements":[{"statement":"MERGE (s:Entity {name: 'Stack Tecnologico', entityType: 'Stack'}) MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (r)-[:INCLUYE]->(s)"}]} > "%TMP%"
call :RUN "Relacion Standard->Stack"

echo {"statements":[{"statement":"MERGE (d:Entity {name: 'Dependencias Principales', entityType: 'Dependencies'}) SET d.web = 'spring-boot-starter-web', d.actuator = 'spring-boot-starter-actuator', d.validation = 'spring-boot-starter-validation', d.kafka = 'spring-kafka', d.jdbc = 'spring-boot-starter-jdbc', d.postgresql = 'postgresql:42.7.2', d.openapi = 'springdoc-openapi-starter-webmvc-ui:2.8.12', d.webflux = 'spring-webflux (solo cliente)', d.resilience4j = 'resilience4j-spring-boot3:2.2.0', d.lombok = 'lombok (compile only)', d.logback = 'logback-awslogs-appender:1.6.0', d.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Dependencias Principales"

echo {"statements":[{"statement":"MERGE (s:Entity {name: 'Stack Tecnologico', entityType: 'Stack'}) MERGE (d:Entity {name: 'Dependencias Principales', entityType: 'Dependencies'}) MERGE (s)-[:CONTIENE]->(d)"}]} > "%TMP%"
call :RUN "Relacion Stack->Dependencias"

REM =============================================================
echo [3/8] Actualizando Arquitectura y Principios...

echo {"statements":[{"statement":"MERGE (a:Entity {name: 'Arquitectura Capas', entityType: 'Architecture'}) SET a.capa1 = 'Kafka Input Layer: XxxKafkaListener consume topic input', a.capa2 = 'Orchestration Layer: XxxProcessor coordina flujo completo', a.capa3 = 'Domain Service + Repository + Kafka Producer + External API Client', a.capa4 = 'Infrastructure Layer: PostgreSQL Aurora + Kafka Topics + External APIs', a.tipo = 'Event-Driven Microservice', a.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Arquitectura Capas"

echo {"statements":[{"statement":"MERGE (a:Entity {name: 'Arquitectura Capas', entityType: 'Architecture'}) MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (r)-[:DEFINE]->(a)"}]} > "%TMP%"
call :RUN "Relacion Standard->Arquitectura"

echo {"statements":[{"statement":"MERGE (p:Entity {name: 'Principios Arquitectonicos', entityType: 'Principles'}) SET p.p1 = 'Separation of Concerns: cada capa tiene responsabilidades bien definidas', p.p2 = 'Dependency Inversion: capas superiores dependen de interfaces no de implementaciones', p.p3 = 'Single Responsibility: cada clase tiene una unica responsabilidad', p.p4 = 'Domain-Driven Design: organizacion por dominios de negocio no por capas tecnicas', p.p5 = 'Factory Pattern: reutilizacion de configuracion mediante factory methods', p.p6 = 'Template Method Pattern: algoritmos base con customizacion especifica', p.p7 = 'Service Layer Pattern: interfaces mas implementaciones separadas', p.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Principios Arquitectonicos"

echo {"statements":[{"statement":"MERGE (a:Entity {name: 'Arquitectura Capas', entityType: 'Architecture'}) MERGE (p:Entity {name: 'Principios Arquitectonicos', entityType: 'Principles'}) MERGE (a)-[:APLICA]->(p)"}]} > "%TMP%"
call :RUN "Relacion Arquitectura->Principios"

REM =============================================================
echo [4/8] Actualizando Estructura de Paquetes...

echo {"statements":[{"statement":"MERGE (e:Entity {name: 'Estructura Paquetes', entityType: 'PackageStructure'}) SET e.raiz = 'src/main/java/cl/klap/bysf/{modulo}/{aplicacion}/', e.global = 'global/: config/ + model/dto/ + enums/ + utils/ + exceptions/', e.dominio = 'dominio/{nombre_dominio}/: config/ + listener/ + services/ + services/impl/ + services/client/ + repository/ + model/ + exceptions/', e.regla1 = 'global/: codigo compartido entre multiples dominios', e.regla2 = 'dominio/: codigo especifico de un dominio de negocio', e.regla3 = 'services/: solo interfaces (contratos)', e.regla4 = 'services/impl/: solo implementaciones con @Service', e.regla5 = 'services/client/: clientes HTTP externos', e.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Estructura Paquetes"

echo {"statements":[{"statement":"MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (e:Entity {name: 'Estructura Paquetes', entityType: 'PackageStructure'}) MERGE (r)-[:DEFINE]->(e)"}]} > "%TMP%"
call :RUN "Relacion Standard->Estructura"

REM =============================================================
echo [5/8] Actualizando Kafka Config y Topics...

echo {"statements":[{"statement":"MERGE (k:Entity {name: 'Kafka Config Standard', entityType: 'KafkaConfig'}) SET k.clase = 'global/config/KafkaConfig.java', k.nota = 'NO es @Configuration - es clase base abstracta', k.ackMode = 'MANUAL - control explicito de commits at-least-once', k.maxPollRecords = 'max.poll.records=1 - procesa de a 1 para backpressure y evitar timeouts', k.metricas = 'enable.metrics.push=false - CRITICO para evitar OOM en MSK/Confluent', k.seguridad = 'local: PLAINTEXT, otros perfiles: SASL_SSL con AWS_MSK_IAM', k.deserializer = 'ErrorHandlingDeserializer como wrapper de JsonDeserializer - mensajes malformados van a DLQ automaticamente', k.reintentos = '3 reintentos con 5s backoff antes de DLQ', k.idempotencia = 'ACKS=all en producers', k.nonRetryable = 'NonRetryableClientDataException para errores deterministas - va a DLQ sin reintentos', k.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Kafka Config Standard"

echo {"statements":[{"statement":"MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (k:Entity {name: 'Kafka Config Standard', entityType: 'KafkaConfig'}) MERGE (r)-[:DEFINE]->(k)"}]} > "%TMP%"
call :RUN "Relacion Standard->Kafka"

echo {"statements":[{"statement":"MERGE (t:Entity {name: 'Kafka Topics Standard', entityType: 'KafkaTopics'}) SET t.input = 'xxx-input-topic: topic de entrada que consume el listener', t.output = 'xxx-output-topic: topic de salida que publica el producer', t.notification = 'bysf-liqsvbo-notificacion: topic de notificaciones cross-domain', t.dlq = 'xxx-dlq-topic: dead letter queue para mensajes fallidos', t.groupId = 'xxx-consumer-group (sufijo -local en perfil local)', t.envio = 'SINCRONICO en dominios financieros - usa .get() para garantizar consistencia', t.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Kafka Topics Standard"

echo {"statements":[{"statement":"MERGE (k:Entity {name: 'Kafka Config Standard', entityType: 'KafkaConfig'}) MERGE (t:Entity {name: 'Kafka Topics Standard', entityType: 'KafkaTopics'}) MERGE (k)-[:GESTIONA]->(t)"}]} > "%TMP%"
call :RUN "Relacion Kafka->Topics"

REM =============================================================
echo [6/8] Actualizando Persistencia...

echo {"statements":[{"statement":"MERGE (d:Entity {name: 'Persistencia Standard', entityType: 'Database'}) SET d.motor = 'PostgreSQL Aurora (AWS)', d.acceso = 'JdbcTemplate - NO JPA/Hibernate', d.queries = 'Centralizadas en ConstantsQuery.java - no hardcodear SQL', d.paginacion = 'Cursor-based por PK para tablas con mas de 500 registros - NO OFFSET/LIMIT', d.rowMappers = 'En paquete mapper/ cuando son complejos 20+ columnas o reutilizados', d.cache = 'Cache con TTL en repositorio para datos de configuracion leidos en cada mensaje', d.auditoria = 'AuditoriaXxxRepository para trazabilidad de todas las operaciones', d.errorHandling = 'Envolver DataAccessException en XxxPersistenceException', d.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Persistencia Standard"

echo {"statements":[{"statement":"MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (d:Entity {name: 'Persistencia Standard', entityType: 'Database'}) MERGE (r)-[:DEFINE]->(d)"}]} > "%TMP%"
call :RUN "Relacion Standard->DB"

REM =============================================================
echo [7/8] Actualizando Convenciones y Reglas DO/DONT...

echo {"statements":[{"statement":"MERGE (c:Entity {name: 'Convenciones Naming', entityType: 'NamingConventions'}) SET c.interfaces = 'XxxService XxxProcessor XxxRepository', c.implementaciones = 'XxxServiceImpl XxxProcessorImpl con @Service', c.dtos = 'XxxInputDto XxxOutputDto XxxRequestDto XxxResponseDto', c.listeners = 'XxxKafkaListener con @Component', c.configs = 'XxxConfig XxxKafkaConfig XxxClientConfig con @Configuration', c.exceptions = 'XxxException XxxClientException XxxPersistenceException', c.metodos = 'procesarXxx() consultarXxx() registrarXxx() para servicios - findById() findAll() insert() update() para repos - consumir() enviarMensaje() para kafka', c.javadoc = 'OBLIGATORIO en todos los metodos - debe explicar objetivo o funcionamiento del metodo', c.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Convenciones Naming"

echo {"statements":[{"statement":"MERGE (l:Entity {name: 'Convenciones Logging', entityType: 'LoggingConventions'}) SET l.error = 'ERROR: errores que requieren investigacion inmediata', l.warn = 'WARN: situaciones anormales pero recuperables', l.info = 'INFO: inicio/fin procesamiento publicacion Kafka', l.debug = 'DEBUG: payloads queries SQL - solo en local', l.contexto = 'Incluir siempre idProceso y codigoSucursal en logs', l.emojis = 'Recomendado: check exito X error advertencia sobre mensaje-recibido mensaje-enviado rojo-circuit-breaker', l.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Convenciones Logging"

echo {"statements":[{"statement":"MERGE (do_node:Entity {name: 'Reglas DO', entityType: 'BestPractices'}) SET do_node.r1 = 'Usar service interfaces: siempre definir interface antes de implementacion', do_node.r2 = 'Usar Lombok: @Data @Builder @RequiredArgsConstructor @Slf4j', do_node.r3 = 'Logging apropiado: DEBUG local INFO produccion - incluir idProceso y codigoSucursal', do_node.r4 = 'Tests unitarios: 95% cobertura minima con JaCoCo', do_node.r5 = 'Excepciones custom por dominio: XxxException XxxClientException XxxPersistenceException', do_node.r6 = 'JdbcTemplate para PostgreSQL - nunca JPA/Hibernate', do_node.r7 = 'Factory Pattern para Kafka: extender KafkaConfig base', do_node.r8 = 'Naming DTOs consistente: InputDto OutputDto RequestDto ResponseDto', do_node.r9 = 'AckMode MANUAL en Kafka para at-least-once', do_node.r10 = 'max.poll.records=1 para backpressure', do_node.r11 = 'enable.metrics.push=false CRITICO para evitar OOM en MSK', do_node.r12 = 'ErrorHandlingDeserializer como wrapper de JsonDeserializer', do_node.r13 = 'Paginacion cursor-based para tablas con mas de 500 registros', do_node.r14 = 'Cache con TTL en repositorio para datos de configuracion', do_node.r15 = 'Envio Kafka sincrono en dominios financieros', do_node.r16 = 'Timeout explicito 3s en PostgresHealthIndicator', do_node.r17 = 'RowMappers en paquete mapper/ para 20+ columnas o reutilizados', do_node.r18 = 'Clasificar errores listener: deterministas a DLQ inmediato vs infraestructura re-throw', do_node.r19 = 'NonRetryableClientDataException para errores irrecuperables hacia DLQ sin reintentos', do_node.r20 = 'Ajustar max.poll.interval.ms segun tiempo real de procesamiento con AtomicLong', do_node.r21 = 'JavaDoc OBLIGATORIO en todos los metodos explicando objetivo o funcionamiento', do_node.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Reglas DO (21 reglas)"

echo {"statements":[{"statement":"MERGE (dont:Entity {name: 'Reglas DONT', entityType: 'AntiPatterns'}) SET dont.r1 = 'No duplicar configuracion Kafka: extender la clase base KafkaConfig', dont.r2 = 'No crear nuevos error handlers Kafka sin extender el de KafkaConfig', dont.r3 = 'No modificar NotificationMessageDto sin coordinacion cross-team', dont.r4 = 'No usar JPA/Hibernate: arquitectura basada en JDBC puro con JdbcTemplate', dont.r5 = 'No hacer bypass del service layer: siempre usar las interfaces', dont.r6 = 'No usar OFFSET/LIMIT para paginacion sobre tablas grandes: cursor-based por PK', dont.r7 = 'No crear multiples consumer groups para el mismo topic sin justificacion documentada', dont.r8 = 'No omitir enable.metrics.push=false: provoca OOM progresivo en MSK en produccion', dont.r9 = 'No hardcodear SQL fuera de ConstantsQuery', dont.r10 = 'No ignorar max.poll.interval.ms: si procesamiento supera el intervalo Kafka expulsa al consumer', dont.r11 = 'No usar cache sin TTL en repositorios: datos congelados generan bugs dificiles de diagnosticar', dont.r12 = 'No enviar a DLQ desde listener para errores de infraestructura: dejar que KafkaConfig maneje reintentos', dont.r13 = 'No omitir JavaDoc en metodos publicos', dont.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Reglas DONT (13 reglas)"

echo {"statements":[{"statement":"MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (c:Entity {name: 'Convenciones Naming', entityType: 'NamingConventions'}) MERGE (l:Entity {name: 'Convenciones Logging', entityType: 'LoggingConventions'}) MERGE (do_node:Entity {name: 'Reglas DO', entityType: 'BestPractices'}) MERGE (dont:Entity {name: 'Reglas DONT', entityType: 'AntiPatterns'}) MERGE (r)-[:DEFINE]->(c) MERGE (r)-[:DEFINE]->(l) MERGE (r)-[:DEFINE]->(do_node) MERGE (r)-[:DEFINE]->(dont)"}]} > "%TMP%"
call :RUN "Relaciones Standard->Convenciones"

REM =============================================================
echo [8/8] Actualizando Templates de codigo...

echo {"statements":[{"statement":"MERGE (t:Entity {name: 'Template KafkaConfig Dominio', entityType: 'CodeTemplate'}) SET t.clase = 'XxxKafkaConfig extends KafkaConfig', t.anotaciones = '@Configuration @EnableKafka', t.beans = 'xxxConsumerFactory() + xxxListenerContainerFactory() + xxxProducerFactory() + xxxKafkaTemplate() + notificationKafkaTemplate() + dlqKafkaTemplate()', t.patron = 'Extender KafkaConfig base y usar factory methods protegidos', t.nota = 'NO duplicar logica de configuracion: usar createConsumerFactory() createProducerFactory() createKafkaTemplate() createListenerContainerFactoryWithDlq()', t.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Template KafkaConfig Dominio"

echo {"statements":[{"statement":"MERGE (t:Entity {name: 'Template KafkaListener', entityType: 'CodeTemplate'}) SET t.clase = 'XxxKafkaListener', t.anotaciones = '@Component @Slf4j @RequiredArgsConstructor', t.metodo = 'consumir(@Payload XxxInputDto mensaje, @Header topic/partition/offset, Acknowledgment)', t.flujo = '1-validarMensaje 2-xxxProcessor.procesarXxx 3-acknowledgment.acknowledge 4-trackear tiempo procesamiento', t.errorDeterminista = 'IllegalArgumentException o IllegalStateException -> enviarADlqManual + acknowledge', t.errorInfraestructura = 'Exception generica -> re-throw para que KafkaConfig maneje reintentos automaticos', t.circuitBreaker = 'AtomicInteger consecutiveFailures, threshold=10, reset timeout=60s', t.tracking = 'AtomicLong maxProcessingTimeMs para ajustar max.poll.interval.ms', t.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Template KafkaListener"

echo {"statements":[{"statement":"MERGE (t:Entity {name: 'Template Processor', entityType: 'CodeTemplate'}) SET t.interface = 'XxxProcessor en services/', t.impl = 'XxxProcessorImpl en services/impl/ con @Service @Slf4j @RequiredArgsConstructor', t.patron = 'Saga: 1-validar 2-consultar API externa 3-procesar logica negocio 4-persistir DB 5-publicar Kafka output 6-publicar notificacion', t.compensacion = 'Fallos en pasos 2-6: auditar como PENDIENTE o ERROR para retry manual', t.nota = 'Orquestador principal - coordina todos los servicios del dominio', t.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Template Processor"

echo {"statements":[{"statement":"MERGE (t:Entity {name: 'Template Repository', entityType: 'CodeTemplate'}) SET t.clase = 'XxxRepository con @Repository @RequiredArgsConstructor @Slf4j', t.dependencia = 'JdbcTemplate (inyeccion por constructor)', t.queries = 'Siempre usar ConstantsQuery.XXX - NUNCA hardcodear SQL inline', t.paginacion = 'Cursor-based: WHERE id > :lastId ORDER BY id LIMIT :pageSize para tablas grandes', t.rowMapper = 'En paquete mapper/ si tiene 20+ columnas o se reutiliza en multiples metodos', t.cache = 'Cache con TTL para datos de configuracion leidos frecuentemente', t.errores = 'Envolver DataAccessException en XxxPersistenceException', t.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Template Repository"

echo {"statements":[{"statement":"MERGE (t:Entity {name: 'Template WebClient', entityType: 'CodeTemplate'}) SET t.config = 'XxxClientConfig @Configuration con WebClient Bean y timeout explicitoRN', t.cliente = 'XxxClient @Component con WebClient inyectado', t.retry = 'Retry.fixedDelay(maxAttempts, backoffDelay) - NO reintenta IllegalArgumentException', t.errores = 'onStatus 4xx -> XxxClientException con statusCode + body / 5xx -> igual', t.envio = 'SIEMPRE .block() sincrono para dominios financieros', t.timeout = 'CONNECT_TIMEOUT + responseTimeout + ReadTimeoutHandler + WriteTimeoutHandler', t.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Template WebClient"

echo {"statements":[{"statement":"MERGE (t:Entity {name: 'Template Excepciones', entityType: 'CodeTemplate'}) SET t.base = 'XxxException extends RuntimeException con constructores String y String+Throwable', t.cliente = 'XxxClientException extends XxxException con statusCode + responseBody', t.persistencia = 'XxxPersistenceException extends XxxException', t.nonRetryable = 'NonRetryableClientDataException para errores de datos irrecuperables DLQ sin reintentos', t.jerarquia = 'RuntimeException -> KafkaMessageException / JsonProcessingException / XxxException -> XxxClientException / XxxPersistenceException', t.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Template Excepciones"

echo {"statements":[{"statement":"MERGE (t:Entity {name: 'Template Testing', entityType: 'CodeTemplate'}) SET t.framework = '@ExtendWith(MockitoExtension.class) JUnit 5 + Mockito + AssertJ', t.estructura = '@Mock dependencias + @InjectMocks sujeto + @Captor para verificar argumentos', t.patron = 'Arrange (setup mocks) + Act (ejecutar) + Assert (verificar resultado y verificar interacciones)', t.cobertura = '95% minimo con JaCoCo - fallar build si no se alcanza', t.webClient = 'MockWebServer para tests de XxxClient - simular respuestas HTTP', t.nombrado = 'testScenarioExitoso() testScenarioConError() testScenarioConValidacion()', t.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Template Testing"

echo {"statements":[{"statement":"MERGE (t:Entity {name: 'Template OpenAPI', entityType: 'CodeTemplate'}) SET t.clase = 'OpenApiConfig @Configuration en global/config/', t.bean = '@Bean OpenAPI con Info: title + version + description', t.nota = 'Disponible en /swagger-ui.html y /v3/api-docs en perfiles local y develop', t.updatedAt = datetime()"}]} > "%TMP%"
call :RUN "Template OpenAPI"

echo {"statements":[{"statement":"MATCH (r:Entity {name: 'Standard KLAP BYSF'}) MATCH (t:Entity) WHERE t.entityType = 'CodeTemplate' MERGE (r)-[:PROVEE]->(t)"}]} > "%TMP%"
call :RUN "Relaciones Standard->Templates"

REM ── Verificacion final ─────────────────────────────────────
echo.
echo ── Verificacion del grafo (Standard vs Memoria del equipo) ──
echo {"statements":[{"statement":"MATCH (n:Entity) RETURN n.entityType as tipo, count(n) as total ORDER BY total DESC"}]} > "%TMP%"
curl -s -u "%NEO4J_USER%:%NEO4J_PASS%" "%BASE_URL%/db/%USE_DB%/tx/commit" -H "Content-Type: application/json" -d @"%TMP%"
echo.

del "%TMP%" >nul 2>&1

echo.
echo =====================================================
echo   [OK] Standard actualizado. Memoria preservada.
echo.
echo   Nodos actualizados (MERGE, sin borrar memoria):
echo   - Standard KLAP BYSF (updatedAt = now)
echo   - Stack Tecnologico + Dependencias Principales
echo   - Arquitectura Capas + Principios Arquitectonicos
echo   - Estructura Paquetes
echo   - Kafka Config Standard + Kafka Topics Standard
echo   - Persistencia Standard
echo   - Convenciones Naming + Logging
echo   - Reglas DO (21 reglas) + DONT (13 reglas)
echo   - 8 Templates CodeTemplate
echo.
echo   NO tocados (memoria acumulada del equipo):
echo   - Decision, Fix, Pattern, Convention
echo   - Developer, Service, Bug, Project
echo =====================================================
echo.
echo Verifica en: http://localhost:7474
echo Query: MATCH (n:Entity) RETURN n
echo.

endlocal
exit /b 0

REM =============================================================
:RUN <descripcion>
set _DESC=%~1
<nul set /p "=  -> %_DESC%... "
for /f "delims=" %%i in ('curl -s -o NUL -w "%%{http_code}" -u "%NEO4J_USER%:%NEO4J_PASS%" "%BASE_URL%/db/%USE_DB%/tx/commit" -H "Content-Type: application/json" -d @"%TMP%" 2^>NUL') do set _ST=%%i
if "%_ST%"=="200" (echo [OK]) else (if "%_ST%"=="201" (echo [OK]) else (echo [WARN] HTTP %_ST%))
exit /b 0
