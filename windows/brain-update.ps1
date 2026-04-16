# =============================================================
# brain-update.ps1 — Sincronizacion incremental de Neo4j
# Actualiza nodos del Standard KLAP BYSF sin borrar memoria
# Ejecutar cuando cambie ARQUITECTURA_REFERENCIA.md
# Requiere: Neo4j corriendo (brain.bat up o brain.ps1 up)
#
# Si PowerShell bloquea la ejecucion, corre primero:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# =============================================================

$NEO4J_HOST = "localhost"
$NEO4J_PORT = "7474"
$NEO4J_USER = "neo4j"
$NEO4J_PASS = "team-brain-2025"
$BASE_URL   = "http://${NEO4J_HOST}:${NEO4J_PORT}"
$USE_DB     = "neo4j"
$ENDPOINT   = "${BASE_URL}/db/${USE_DB}/tx/commit"
$HEADERS    = @{ "Content-Type" = "application/json" }
$CREDENTIAL = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${NEO4J_USER}:${NEO4J_PASS}"))
$HEADERS["Authorization"] = "Basic $CREDENTIAL"

$UpdatedNodes = [System.Collections.Generic.List[string]]::new()

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Team Brain -- Sincronizacion incremental" -ForegroundColor Cyan
Write-Host "  Standard KLAP BYSF (solo nodos de referencia)" -ForegroundColor Cyan
Write-Host "  NUNCA borra Decision, Fix, Pattern, Developer..." -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# ── Funcion principal de MERGE ────────────────────────────────
function Invoke-Merge {
    param(
        [string]$Descripcion,
        [string]$Cypher
    )
    Write-Host "  -> $Descripcion... " -NoNewline

    $body = @{
        statements = @(
            @{ statement = $Cypher }
        )
    } | ConvertTo-Json -Depth 10 -Compress

    try {
        $response = Invoke-RestMethod -Uri $ENDPOINT -Method POST -Headers $HEADERS -Body $body -ErrorAction Stop
        if ($response.errors -and $response.errors.Count -gt 0) {
            Write-Host "[WARN] $($response.errors[0].message)" -ForegroundColor Yellow
        } else {
            Write-Host "[OK]" -ForegroundColor Green
            $script:UpdatedNodes.Add($Descripcion)
        }
    } catch {
        Write-Host "[ERROR] $_" -ForegroundColor Red
    }
}

# ── Verificar Neo4j ───────────────────────────────────────────
Write-Host "Verificando conexion a Neo4j..." -NoNewline
try {
    $pingBody = '{"statements":[{"statement":"RETURN 1"}]}'
    $pingResp = Invoke-RestMethod -Uri $ENDPOINT -Method POST -Headers $HEADERS -Body $pingBody -ErrorAction Stop
    Write-Host " [OK] Neo4j disponible." -ForegroundColor Green
} catch {
    Write-Host " [ERROR] Neo4j no disponible. Ejecuta: .\brain.ps1 up" -ForegroundColor Red
    exit 1
}
Write-Host ""

# =============================================================
Write-Host "[1/8] Actualizando nodo raiz Standard KLAP BYSF..." -ForegroundColor Cyan

Invoke-Merge "Standard KLAP BYSF (updatedAt)" `
    "MERGE (s:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) SET s.version = '1.2.0', s.description = 'Arquitectura de referencia para microservicios KLAP BYSF', s.team = 'Liquidacion SVBO', s.updatedAt = datetime()"

# =============================================================
Write-Host "[2/8] Actualizando Stack Tecnologico..." -ForegroundColor Cyan

Invoke-Merge "Stack Tecnologico" `
    "MERGE (s:Entity {name: 'Stack Tecnologico', entityType: 'Stack'}) SET s.java = 'Java 21', s.gradle = 'Gradle 9.0.0', s.springBoot = 'Spring Boot 3.5.11', s.springCloud = 'Spring Cloud 2025.0.0', s.updatedAt = datetime()"

Invoke-Merge "Relacion Standard->Stack" `
    "MERGE (s:Entity {name: 'Stack Tecnologico', entityType: 'Stack'}) MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (r)-[:INCLUYE]->(s)"

Invoke-Merge "Dependencias Principales" `
    "MERGE (d:Entity {name: 'Dependencias Principales', entityType: 'Dependencies'}) SET d.web = 'spring-boot-starter-web', d.actuator = 'spring-boot-starter-actuator', d.validation = 'spring-boot-starter-validation', d.kafka = 'spring-kafka', d.jdbc = 'spring-boot-starter-jdbc', d.postgresql = 'postgresql:42.7.2', d.openapi = 'springdoc-openapi-starter-webmvc-ui:2.8.12', d.webflux = 'spring-webflux (solo cliente)', d.resilience4j = 'resilience4j-spring-boot3:2.2.0', d.lombok = 'lombok (compile only)', d.logback = 'logback-awslogs-appender:1.6.0', d.updatedAt = datetime()"

Invoke-Merge "Relacion Stack->Dependencias" `
    "MERGE (s:Entity {name: 'Stack Tecnologico', entityType: 'Stack'}) MERGE (d:Entity {name: 'Dependencias Principales', entityType: 'Dependencies'}) MERGE (s)-[:CONTIENE]->(d)"

# =============================================================
Write-Host "[3/8] Actualizando Arquitectura y Principios..." -ForegroundColor Cyan

Invoke-Merge "Arquitectura Capas" `
    "MERGE (a:Entity {name: 'Arquitectura Capas', entityType: 'Architecture'}) SET a.capa1 = 'Kafka Input Layer: XxxKafkaListener consume topic input', a.capa2 = 'Orchestration Layer: XxxProcessor coordina flujo completo', a.capa3 = 'Domain Service + Repository + Kafka Producer + External API Client', a.capa4 = 'Infrastructure Layer: PostgreSQL Aurora + Kafka Topics + External APIs', a.tipo = 'Event-Driven Microservice', a.updatedAt = datetime()"

Invoke-Merge "Relacion Standard->Arquitectura" `
    "MERGE (a:Entity {name: 'Arquitectura Capas', entityType: 'Architecture'}) MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (r)-[:DEFINE]->(a)"

Invoke-Merge "Principios Arquitectonicos" `
    "MERGE (p:Entity {name: 'Principios Arquitectonicos', entityType: 'Principles'}) SET p.p1 = 'Separation of Concerns: cada capa tiene responsabilidades bien definidas', p.p2 = 'Dependency Inversion: capas superiores dependen de interfaces no de implementaciones', p.p3 = 'Single Responsibility: cada clase tiene una unica responsabilidad', p.p4 = 'Domain-Driven Design: organizacion por dominios de negocio no por capas tecnicas', p.p5 = 'Factory Pattern: reutilizacion de configuracion mediante factory methods', p.p6 = 'Template Method Pattern: algoritmos base con customizacion especifica', p.p7 = 'Service Layer Pattern: interfaces mas implementaciones separadas', p.updatedAt = datetime()"

Invoke-Merge "Relacion Arquitectura->Principios" `
    "MERGE (a:Entity {name: 'Arquitectura Capas', entityType: 'Architecture'}) MERGE (p:Entity {name: 'Principios Arquitectonicos', entityType: 'Principles'}) MERGE (a)-[:APLICA]->(p)"

# =============================================================
Write-Host "[4/8] Actualizando Estructura de Paquetes..." -ForegroundColor Cyan

Invoke-Merge "Estructura Paquetes" `
    "MERGE (e:Entity {name: 'Estructura Paquetes', entityType: 'PackageStructure'}) SET e.raiz = 'src/main/java/cl/klap/bysf/{modulo}/{aplicacion}/', e.global = 'global/: config/ + model/dto/ + enums/ + utils/ + exceptions/', e.dominio = 'dominio/{nombre_dominio}/: config/ + listener/ + services/ + services/impl/ + services/client/ + repository/ + model/ + exceptions/', e.regla1 = 'global/: codigo compartido entre multiples dominios', e.regla2 = 'dominio/: codigo especifico de un dominio de negocio', e.regla3 = 'services/: solo interfaces (contratos)', e.regla4 = 'services/impl/: solo implementaciones con @Service', e.regla5 = 'services/client/: clientes HTTP externos', e.updatedAt = datetime()"

Invoke-Merge "Relacion Standard->Estructura" `
    "MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (e:Entity {name: 'Estructura Paquetes', entityType: 'PackageStructure'}) MERGE (r)-[:DEFINE]->(e)"

# =============================================================
Write-Host "[5/8] Actualizando Kafka Config y Topics..." -ForegroundColor Cyan

Invoke-Merge "Kafka Config Standard" `
    "MERGE (k:Entity {name: 'Kafka Config Standard', entityType: 'KafkaConfig'}) SET k.clase = 'global/config/KafkaConfig.java', k.nota = 'NO es @Configuration - es clase base abstracta', k.ackMode = 'MANUAL - control explicito de commits at-least-once', k.maxPollRecords = 'max.poll.records=1 - procesa de a 1 para backpressure y evitar timeouts', k.metricas = 'enable.metrics.push=false - CRITICO para evitar OOM en MSK/Confluent', k.seguridad = 'local: PLAINTEXT, otros perfiles: SASL_SSL con AWS_MSK_IAM', k.deserializer = 'ErrorHandlingDeserializer como wrapper de JsonDeserializer - mensajes malformados van a DLQ automaticamente', k.reintentos = '3 reintentos con 5s backoff antes de DLQ', k.idempotencia = 'ACKS=all en producers', k.nonRetryable = 'NonRetryableClientDataException para errores deterministas - va a DLQ sin reintentos', k.updatedAt = datetime()"

Invoke-Merge "Relacion Standard->Kafka" `
    "MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (k:Entity {name: 'Kafka Config Standard', entityType: 'KafkaConfig'}) MERGE (r)-[:DEFINE]->(k)"

Invoke-Merge "Kafka Topics Standard" `
    "MERGE (t:Entity {name: 'Kafka Topics Standard', entityType: 'KafkaTopics'}) SET t.input = 'xxx-input-topic: topic de entrada que consume el listener', t.output = 'xxx-output-topic: topic de salida que publica el producer', t.notification = 'bysf-liqsvbo-notificacion: topic de notificaciones cross-domain', t.dlq = 'xxx-dlq-topic: dead letter queue para mensajes fallidos', t.groupId = 'xxx-consumer-group (sufijo -local en perfil local)', t.envio = 'SINCRONICO en dominios financieros - usa .get() para garantizar consistencia', t.updatedAt = datetime()"

Invoke-Merge "Relacion Kafka->Topics" `
    "MERGE (k:Entity {name: 'Kafka Config Standard', entityType: 'KafkaConfig'}) MERGE (t:Entity {name: 'Kafka Topics Standard', entityType: 'KafkaTopics'}) MERGE (k)-[:GESTIONA]->(t)"

# =============================================================
Write-Host "[6/8] Actualizando Persistencia..." -ForegroundColor Cyan

Invoke-Merge "Persistencia Standard" `
    "MERGE (d:Entity {name: 'Persistencia Standard', entityType: 'Database'}) SET d.motor = 'PostgreSQL Aurora (AWS)', d.acceso = 'JdbcTemplate - NO JPA/Hibernate', d.queries = 'Centralizadas en ConstantsQuery.java - no hardcodear SQL', d.paginacion = 'Cursor-based por PK para tablas con mas de 500 registros - NO OFFSET/LIMIT', d.rowMappers = 'En paquete mapper/ cuando son complejos 20+ columnas o reutilizados', d.cache = 'Cache con TTL en repositorio para datos de configuracion leidos en cada mensaje', d.auditoria = 'AuditoriaXxxRepository para trazabilidad de todas las operaciones', d.errorHandling = 'Envolver DataAccessException en XxxPersistenceException', d.updatedAt = datetime()"

Invoke-Merge "Relacion Standard->DB" `
    "MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (d:Entity {name: 'Persistencia Standard', entityType: 'Database'}) MERGE (r)-[:DEFINE]->(d)"

# =============================================================
Write-Host "[7/8] Actualizando Convenciones y Reglas DO/DONT..." -ForegroundColor Cyan

Invoke-Merge "Convenciones Naming" `
    "MERGE (c:Entity {name: 'Convenciones Naming', entityType: 'NamingConventions'}) SET c.interfaces = 'XxxService XxxProcessor XxxRepository', c.implementaciones = 'XxxServiceImpl XxxProcessorImpl con @Service', c.dtos = 'XxxInputDto XxxOutputDto XxxRequestDto XxxResponseDto', c.listeners = 'XxxKafkaListener con @Component', c.configs = 'XxxConfig XxxKafkaConfig XxxClientConfig con @Configuration', c.exceptions = 'XxxException XxxClientException XxxPersistenceException', c.metodos = 'procesarXxx() consultarXxx() registrarXxx() para servicios - findById() findAll() insert() update() para repos - consumir() enviarMensaje() para kafka', c.javadoc = 'OBLIGATORIO en todos los metodos - debe explicar objetivo o funcionamiento del metodo', c.updatedAt = datetime()"

Invoke-Merge "Convenciones Logging" `
    "MERGE (l:Entity {name: 'Convenciones Logging', entityType: 'LoggingConventions'}) SET l.error = 'ERROR: errores que requieren investigacion inmediata', l.warn = 'WARN: situaciones anormales pero recuperables', l.info = 'INFO: inicio/fin procesamiento publicacion Kafka', l.debug = 'DEBUG: payloads queries SQL - solo en local', l.contexto = 'Incluir siempre idProceso y codigoSucursal en logs', l.emojis = 'Recomendado: check exito X error advertencia sobre mensaje-recibido mensaje-enviado rojo-circuit-breaker', l.updatedAt = datetime()"

Invoke-Merge "Reglas DO (21 reglas)" `
    "MERGE (do_node:Entity {name: 'Reglas DO', entityType: 'BestPractices'}) SET do_node.r1 = 'Usar service interfaces: siempre definir interface antes de implementacion', do_node.r2 = 'Usar Lombok: @Data @Builder @RequiredArgsConstructor @Slf4j', do_node.r3 = 'Logging apropiado: DEBUG local INFO produccion - incluir idProceso y codigoSucursal', do_node.r4 = 'Tests unitarios: 95% cobertura minima con JaCoCo', do_node.r5 = 'Excepciones custom por dominio: XxxException XxxClientException XxxPersistenceException', do_node.r6 = 'JdbcTemplate para PostgreSQL - nunca JPA/Hibernate', do_node.r7 = 'Factory Pattern para Kafka: extender KafkaConfig base', do_node.r8 = 'Naming DTOs consistente: InputDto OutputDto RequestDto ResponseDto', do_node.r9 = 'AckMode MANUAL en Kafka para at-least-once', do_node.r10 = 'max.poll.records=1 para backpressure', do_node.r11 = 'enable.metrics.push=false CRITICO para evitar OOM en MSK', do_node.r12 = 'ErrorHandlingDeserializer como wrapper de JsonDeserializer', do_node.r13 = 'Paginacion cursor-based para tablas con mas de 500 registros', do_node.r14 = 'Cache con TTL en repositorio para datos de configuracion', do_node.r15 = 'Envio Kafka sincrono en dominios financieros', do_node.r16 = 'Timeout explicito 3s en PostgresHealthIndicator', do_node.r17 = 'RowMappers en paquete mapper/ para 20+ columnas o reutilizados', do_node.r18 = 'Clasificar errores listener: deterministas a DLQ inmediato vs infraestructura re-throw', do_node.r19 = 'NonRetryableClientDataException para errores irrecuperables hacia DLQ sin reintentos', do_node.r20 = 'Ajustar max.poll.interval.ms segun tiempo real de procesamiento con AtomicLong', do_node.r21 = 'JavaDoc OBLIGATORIO en todos los metodos explicando objetivo o funcionamiento', do_node.updatedAt = datetime()"

Invoke-Merge "Reglas DONT (13 reglas)" `
    "MERGE (dont:Entity {name: 'Reglas DONT', entityType: 'AntiPatterns'}) SET dont.r1 = 'No duplicar configuracion Kafka: extender la clase base KafkaConfig', dont.r2 = 'No crear nuevos error handlers Kafka sin extender el de KafkaConfig', dont.r3 = 'No modificar NotificationMessageDto sin coordinacion cross-team', dont.r4 = 'No usar JPA/Hibernate: arquitectura basada en JDBC puro con JdbcTemplate', dont.r5 = 'No hacer bypass del service layer: siempre usar las interfaces', dont.r6 = 'No usar OFFSET/LIMIT para paginacion sobre tablas grandes: cursor-based por PK', dont.r7 = 'No crear multiples consumer groups para el mismo topic sin justificacion documentada', dont.r8 = 'No omitir enable.metrics.push=false: provoca OOM progresivo en MSK en produccion', dont.r9 = 'No hardcodear SQL fuera de ConstantsQuery', dont.r10 = 'No ignorar max.poll.interval.ms: si procesamiento supera el intervalo Kafka expulsa al consumer', dont.r11 = 'No usar cache sin TTL en repositorios: datos congelados generan bugs dificiles de diagnosticar', dont.r12 = 'No enviar a DLQ desde listener para errores de infraestructura: dejar que KafkaConfig maneje reintentos', dont.r13 = 'No omitir JavaDoc en metodos publicos', dont.updatedAt = datetime()"

Invoke-Merge "Relaciones Standard->Convenciones" `
    "MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (c:Entity {name: 'Convenciones Naming', entityType: 'NamingConventions'}) MERGE (l:Entity {name: 'Convenciones Logging', entityType: 'LoggingConventions'}) MERGE (do_node:Entity {name: 'Reglas DO', entityType: 'BestPractices'}) MERGE (dont:Entity {name: 'Reglas DONT', entityType: 'AntiPatterns'}) MERGE (r)-[:DEFINE]->(c) MERGE (r)-[:DEFINE]->(l) MERGE (r)-[:DEFINE]->(do_node) MERGE (r)-[:DEFINE]->(dont)"

# =============================================================
Write-Host "[8/8] Actualizando Templates de codigo..." -ForegroundColor Cyan

Invoke-Merge "Template KafkaConfig Dominio" `
    "MERGE (t:Entity {name: 'Template KafkaConfig Dominio', entityType: 'CodeTemplate'}) SET t.clase = 'XxxKafkaConfig extends KafkaConfig', t.anotaciones = '@Configuration @EnableKafka', t.beans = 'xxxConsumerFactory() + xxxListenerContainerFactory() + xxxProducerFactory() + xxxKafkaTemplate() + notificationKafkaTemplate() + dlqKafkaTemplate()', t.patron = 'Extender KafkaConfig base y usar factory methods protegidos', t.nota = 'NO duplicar logica de configuracion: usar createConsumerFactory() createProducerFactory() createKafkaTemplate() createListenerContainerFactoryWithDlq()', t.updatedAt = datetime()"

Invoke-Merge "Template KafkaListener" `
    "MERGE (t:Entity {name: 'Template KafkaListener', entityType: 'CodeTemplate'}) SET t.clase = 'XxxKafkaListener', t.anotaciones = '@Component @Slf4j @RequiredArgsConstructor', t.metodo = 'consumir(@Payload XxxInputDto mensaje, @Header topic/partition/offset, Acknowledgment)', t.flujo = '1-validarMensaje 2-xxxProcessor.procesarXxx 3-acknowledgment.acknowledge 4-trackear tiempo procesamiento', t.errorDeterminista = 'IllegalArgumentException o IllegalStateException -> enviarADlqManual + acknowledge', t.errorInfraestructura = 'Exception generica -> re-throw para que KafkaConfig maneje reintentos automaticos', t.circuitBreaker = 'AtomicInteger consecutiveFailures, threshold=10, reset timeout=60s', t.tracking = 'AtomicLong maxProcessingTimeMs para ajustar max.poll.interval.ms', t.updatedAt = datetime()"

Invoke-Merge "Template Processor" `
    "MERGE (t:Entity {name: 'Template Processor', entityType: 'CodeTemplate'}) SET t.interface = 'XxxProcessor en services/', t.impl = 'XxxProcessorImpl en services/impl/ con @Service @Slf4j @RequiredArgsConstructor', t.patron = 'Saga: 1-validar 2-consultar API externa 3-procesar logica negocio 4-persistir DB 5-publicar Kafka output 6-publicar notificacion', t.compensacion = 'Fallos en pasos 2-6: auditar como PENDIENTE o ERROR para retry manual', t.nota = 'Orquestador principal - coordina todos los servicios del dominio', t.updatedAt = datetime()"

Invoke-Merge "Template Repository" `
    "MERGE (t:Entity {name: 'Template Repository', entityType: 'CodeTemplate'}) SET t.clase = 'XxxRepository con @Repository @RequiredArgsConstructor @Slf4j', t.dependencia = 'JdbcTemplate (inyeccion por constructor)', t.queries = 'Siempre usar ConstantsQuery.XXX - NUNCA hardcodear SQL inline', t.paginacion = 'Cursor-based: WHERE id > :lastId ORDER BY id LIMIT :pageSize para tablas grandes', t.rowMapper = 'En paquete mapper/ si tiene 20+ columnas o se reutiliza en multiples metodos', t.cache = 'Cache con TTL para datos de configuracion leidos frecuentemente', t.errores = 'Envolver DataAccessException en XxxPersistenceException', t.updatedAt = datetime()"

Invoke-Merge "Template WebClient" `
    "MERGE (t:Entity {name: 'Template WebClient', entityType: 'CodeTemplate'}) SET t.config = 'XxxClientConfig @Configuration con WebClient Bean y timeout explicitoRN', t.cliente = 'XxxClient @Component con WebClient inyectado', t.retry = 'Retry.fixedDelay(maxAttempts, backoffDelay) - NO reintenta IllegalArgumentException', t.errores = 'onStatus 4xx -> XxxClientException con statusCode + body / 5xx -> igual', t.envio = 'SIEMPRE .block() sincrono para dominios financieros', t.timeout = 'CONNECT_TIMEOUT + responseTimeout + ReadTimeoutHandler + WriteTimeoutHandler', t.updatedAt = datetime()"

Invoke-Merge "Template Excepciones" `
    "MERGE (t:Entity {name: 'Template Excepciones', entityType: 'CodeTemplate'}) SET t.base = 'XxxException extends RuntimeException con constructores String y String+Throwable', t.cliente = 'XxxClientException extends XxxException con statusCode + responseBody', t.persistencia = 'XxxPersistenceException extends XxxException', t.nonRetryable = 'NonRetryableClientDataException para errores de datos irrecuperables DLQ sin reintentos', t.jerarquia = 'RuntimeException -> KafkaMessageException / JsonProcessingException / XxxException -> XxxClientException / XxxPersistenceException', t.updatedAt = datetime()"

Invoke-Merge "Template Testing" `
    "MERGE (t:Entity {name: 'Template Testing', entityType: 'CodeTemplate'}) SET t.framework = '@ExtendWith(MockitoExtension.class) JUnit 5 + Mockito + AssertJ', t.estructura = '@Mock dependencias + @InjectMocks sujeto + @Captor para verificar argumentos', t.patron = 'Arrange (setup mocks) + Act (ejecutar) + Assert (verificar resultado y verificar interacciones)', t.cobertura = '95% minimo con JaCoCo - fallar build si no se alcanza', t.webClient = 'MockWebServer para tests de XxxClient - simular respuestas HTTP', t.nombrado = 'testScenarioExitoso() testScenarioConError() testScenarioConValidacion()', t.updatedAt = datetime()"

Invoke-Merge "Template OpenAPI" `
    "MERGE (t:Entity {name: 'Template OpenAPI', entityType: 'CodeTemplate'}) SET t.clase = 'OpenApiConfig @Configuration en global/config/', t.bean = '@Bean OpenAPI con Info: title + version + description', t.nota = 'Disponible en /swagger-ui.html y /v3/api-docs en perfiles local y develop', t.updatedAt = datetime()"

Invoke-Merge "Relaciones Standard->Templates" `
    "MATCH (r:Entity {name: 'Standard KLAP BYSF'}) MATCH (t:Entity) WHERE t.entityType = 'CodeTemplate' MERGE (r)-[:PROVEE]->(t)"

# ── Verificacion final ────────────────────────────────────────
Write-Host ""
Write-Host "── Verificacion del grafo (Standard vs Memoria del equipo) ──" -ForegroundColor Cyan

$verifyBody = @{
    statements = @(
        @{ statement = "MATCH (n:Entity) RETURN n.entityType as tipo, count(n) as total ORDER BY total DESC" }
    )
} | ConvertTo-Json -Depth 10 -Compress

try {
    $verifyResp = Invoke-RestMethod -Uri $ENDPOINT -Method POST -Headers $HEADERS -Body $verifyBody -ErrorAction Stop
    Write-Host ""
    Write-Host "  Tipo                  | Total" -ForegroundColor White
    Write-Host "  ----------------------+------" -ForegroundColor DarkGray

    $standardTypes = @("Standard","Stack","Dependencies","Architecture","Principles","PackageStructure","KafkaConfig","KafkaTopics","Database","NamingConventions","LoggingConventions","BestPractices","AntiPatterns","CodeTemplate")
    $teamTypes     = @("Decision","Fix","Pattern","Convention","Developer","Service","Bug","Project")

    foreach ($row in $verifyResp.results[0].data) {
        $tipo  = $row.row[0]
        $total = $row.row[1]
        if ($standardTypes -contains $tipo) {
            Write-Host ("  {0,-22}| {1}" -f $tipo, $total) -ForegroundColor Green
        } elseif ($teamTypes -contains $tipo) {
            Write-Host ("  {0,-22}| {1}  <- memoria equipo" -f $tipo, $total) -ForegroundColor Yellow
        } else {
            Write-Host ("  {0,-22}| {1}" -f $tipo, $total) -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "[WARN] No se pudo obtener conteo: $_" -ForegroundColor Yellow
}

# ── Resumen ───────────────────────────────────────────────────
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  [OK] Standard actualizado. Memoria preservada." -ForegroundColor Green
Write-Host ""
Write-Host "  Nodos actualizados ($($UpdatedNodes.Count) operaciones MERGE):" -ForegroundColor White
Write-Host "  - Standard KLAP BYSF (updatedAt = now)" -ForegroundColor White
Write-Host "  - Stack Tecnologico + Dependencias Principales" -ForegroundColor White
Write-Host "  - Arquitectura Capas + Principios Arquitectonicos" -ForegroundColor White
Write-Host "  - Estructura Paquetes" -ForegroundColor White
Write-Host "  - Kafka Config Standard + Kafka Topics Standard" -ForegroundColor White
Write-Host "  - Persistencia Standard" -ForegroundColor White
Write-Host "  - Convenciones Naming + Logging" -ForegroundColor White
Write-Host "  - Reglas DO (21 reglas) + DONT (13 reglas)" -ForegroundColor White
Write-Host "  - 8 Templates CodeTemplate" -ForegroundColor White
Write-Host ""
Write-Host "  NO tocados (memoria acumulada del equipo):" -ForegroundColor Yellow
Write-Host "  - Decision, Fix, Pattern, Convention" -ForegroundColor Yellow
Write-Host "  - Developer, Service, Bug, Project" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Verifica en: http://localhost:7474"
Write-Host "Query: MATCH (n:Entity) RETURN n"
Write-Host ""
