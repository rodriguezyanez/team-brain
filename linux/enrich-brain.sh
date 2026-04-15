#!/usr/bin/env bash
# =============================================================
# enrich-brain.sh — Carga arquitectura de referencia KLAP BYSF
# Ejecutar DESPUES de init-brain.sh
# Requiere: Neo4j corriendo (docker compose up -d)
# =============================================================

set -e

NEO4J_HOST="${NEO4J_HOST:-localhost}"
NEO4J_PORT="${NEO4J_PORT:-7474}"
NEO4J_USER="${NEO4J_USER:-neo4j}"
NEO4J_PASS="${NEO4J_PASS:-team-brain-2025}"
BASE_URL="http://${NEO4J_HOST}:${NEO4J_PORT}"
USE_DB="${NEO4J_DATABASE:-neo4j}"
TMP=$(mktemp /tmp/neo4j_enrich_XXXXXX.json)

cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

echo ""
echo "====================================================="
echo "  Team Brain -- Carga de arquitectura de referencia"
echo "  KLAP BYSF v1.2.0"
echo "====================================================="
echo ""

# ── Verificar curl ────────────────────────────────────────────
if ! command -v curl &>/dev/null; then
  echo "[ERROR] curl no encontrado. Instálalo con: apt install curl / brew install curl"
  exit 1
fi

# ── Verificar Neo4j ───────────────────────────────────────────
run() {
  local DESC="$1"
  local QUERY="$2"
  printf "  -> %s... " "$DESC"
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${NEO4J_USER}:${NEO4J_PASS}" \
    "${BASE_URL}/db/${USE_DB}/tx/commit" \
    -H "Content-Type: application/json" \
    -d "{\"statements\":[{\"statement\":\"${QUERY}\"}]}" 2>/dev/null || echo "000")
  if [ "$STATUS" = "200" ] || [ "$STATUS" = "201" ]; then
    echo "[OK]"
  else
    echo "[WARN] HTTP ${STATUS}"
  fi
}

printf '{"statements":[{"statement":"RETURN 1"}]}' > "$TMP"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "${NEO4J_USER}:${NEO4J_PASS}" \
  "${BASE_URL}/db/${USE_DB}/tx/commit" \
  -H "Content-Type: application/json" \
  -d @"$TMP" 2>/dev/null || echo "000")
if [ "$STATUS" != "200" ] && [ "$STATUS" != "201" ]; then
  echo "[ERROR] Neo4j no disponible (HTTP ${STATUS}). Ejecuta: docker compose up -d"
  exit 1
fi
echo "[OK] Neo4j disponible. Base de datos: ${USE_DB}"
echo ""

# =============================================================
echo "[1/8] Nodo raiz del estandar..."
run "Nodo Standard KLAP BYSF" \
  "MERGE (s:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) SET s.version = '1.2.0', s.description = 'Arquitectura de referencia para microservicios KLAP BYSF', s.updatedAt = datetime(), s.team = 'Liquidacion SVBO'"

# =============================================================
echo "[2/8] Stack tecnologico..."
run "Stack base" \
  "MERGE (s:Entity {name: 'Stack Tecnologico', entityType: 'Stack'}) SET s.java = 'Java 21', s.gradle = 'Gradle 9.0.0', s.springBoot = 'Spring Boot 3.5.11', s.springCloud = 'Spring Cloud 2025.0.0', s.createdAt = datetime()"

run "Relacion Standard->Stack" \
  "MERGE (s:Entity {name: 'Stack Tecnologico', entityType: 'Stack'}) MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (r)-[:INCLUYE]->(s)"

run "Dependencias" \
  "MERGE (d:Entity {name: 'Dependencias Principales', entityType: 'Dependencies'}) SET d.web = 'spring-boot-starter-web', d.actuator = 'spring-boot-starter-actuator', d.validation = 'spring-boot-starter-validation', d.kafka = 'spring-kafka', d.jdbc = 'spring-boot-starter-jdbc', d.postgresql = 'postgresql:42.7.2', d.openapi = 'springdoc-openapi-starter-webmvc-ui:2.8.12', d.webflux = 'spring-webflux (solo cliente)', d.resilience4j = 'resilience4j-spring-boot3:2.2.0', d.lombok = 'lombok (compile only)', d.logback = 'logback-awslogs-appender:1.6.0'"

run "Relacion Stack->Dependencias" \
  "MERGE (s:Entity {name: 'Stack Tecnologico', entityType: 'Stack'}) MERGE (d:Entity {name: 'Dependencias Principales', entityType: 'Dependencies'}) MERGE (s)-[:CONTIENE]->(d)"

# =============================================================
echo "[3/8] Arquitectura y patrones..."
run "Arquitectura de capas" \
  "MERGE (a:Entity {name: 'Arquitectura Capas', entityType: 'Architecture'}) SET a.capa1 = 'Kafka Input Layer: XxxKafkaListener consume topic input', a.capa2 = 'Orchestration Layer: XxxProcessor coordina flujo completo', a.capa3 = 'Domain Service + Repository + Kafka Producer + External API Client', a.capa4 = 'Infrastructure Layer: PostgreSQL Aurora + Kafka Topics + External APIs', a.tipo = 'Event-Driven Microservice', a.createdAt = datetime()"

run "Relacion Standard->Arquitectura" \
  "MERGE (a:Entity {name: 'Arquitectura Capas', entityType: 'Architecture'}) MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (r)-[:DEFINE]->(a)"

run "Principios arquitectonicos" \
  "MERGE (p:Entity {name: 'Principios Arquitectonicos', entityType: 'Principles'}) SET p.p1 = 'Separation of Concerns: cada capa tiene responsabilidades bien definidas', p.p2 = 'Dependency Inversion: capas superiores dependen de interfaces no de implementaciones', p.p3 = 'Single Responsibility: cada clase tiene una unica responsabilidad', p.p4 = 'Domain-Driven Design: organizacion por dominios de negocio no por capas tecnicas', p.p5 = 'Factory Pattern: reutilizacion de configuracion mediante factory methods', p.p6 = 'Template Method Pattern: algoritmos base con customizacion especifica', p.p7 = 'Service Layer Pattern: interfaces mas implementaciones separadas'"

run "Relacion Arquitectura->Principios" \
  "MERGE (a:Entity {name: 'Arquitectura Capas', entityType: 'Architecture'}) MERGE (p:Entity {name: 'Principios Arquitectonicos', entityType: 'Principles'}) MERGE (a)-[:APLICA]->(p)"

# =============================================================
echo "[4/8] Estructura de paquetes..."
run "Estructura de paquetes" \
  "MERGE (e:Entity {name: 'Estructura Paquetes', entityType: 'PackageStructure'}) SET e.raiz = 'src/main/java/cl/klap/bysf/{modulo}/{aplicacion}/', e.global = 'global/: config/ + model/dto/ + enums/ + utils/ + exceptions/', e.dominio = 'dominio/{nombre_dominio}/: config/ + listener/ + services/ + services/impl/ + services/client/ + repository/ + model/ + exceptions/', e.regla1 = 'global/: codigo compartido entre multiples dominios', e.regla2 = 'dominio/: codigo especifico de un dominio de negocio', e.regla3 = 'services/: solo interfaces (contratos)', e.regla4 = 'services/impl/: solo implementaciones con @Service', e.regla5 = 'services/client/: clientes HTTP externos'"

run "Relacion Standard->Estructura" \
  "MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (e:Entity {name: 'Estructura Paquetes', entityType: 'PackageStructure'}) MERGE (r)-[:DEFINE]->(e)"

# =============================================================
echo "[5/8] Configuracion Kafka..."
run "Kafka config base" \
  "MERGE (k:Entity {name: 'Kafka Config Standard', entityType: 'KafkaConfig'}) SET k.clase = 'global/config/KafkaConfig.java', k.nota = 'NO es @Configuration - es clase base abstracta', k.ackMode = 'MANUAL - control explicito de commits at-least-once', k.maxPollRecords = 'max.poll.records=1 - procesa de a 1 para backpressure y evitar timeouts', k.metricas = 'enable.metrics.push=false - CRITICO para evitar OOM en MSK/Confluent', k.seguridad = 'local: PLAINTEXT, otros perfiles: SASL_SSL con AWS_MSK_IAM', k.deserializer = 'ErrorHandlingDeserializer como wrapper de JsonDeserializer - mensajes malformados van a DLQ automaticamente', k.reintentos = '3 reintentos con 5s backoff antes de DLQ', k.idempotencia = 'ACKS=all en producers', k.nonRetryable = 'NonRetryableClientDataException para errores deterministas - va a DLQ sin reintentos'"

run "Relacion Standard->Kafka" \
  "MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (k:Entity {name: 'Kafka Config Standard', entityType: 'KafkaConfig'}) MERGE (r)-[:DEFINE]->(k)"

run "Kafka topics" \
  "MERGE (t:Entity {name: 'Kafka Topics Standard', entityType: 'KafkaTopics'}) SET t.input = 'xxx-input-topic: topic de entrada que consume el listener', t.output = 'xxx-output-topic: topic de salida que publica el producer', t.notification = 'bysf-liqsvbo-notificacion: topic de notificaciones cross-domain', t.dlq = 'xxx-dlq-topic: dead letter queue para mensajes fallidos', t.groupId = 'xxx-consumer-group (sufijo -local en perfil local)', t.envio = 'SINCRONICO en dominios financieros - usa .get() para garantizar consistencia'"

run "Relacion Kafka->Topics" \
  "MERGE (k:Entity {name: 'Kafka Config Standard', entityType: 'KafkaConfig'}) MERGE (t:Entity {name: 'Kafka Topics Standard', entityType: 'KafkaTopics'}) MERGE (k)-[:GESTIONA]->(t)"

# =============================================================
echo "[6/8] Persistencia y base de datos..."
run "Persistencia standard" \
  "MERGE (d:Entity {name: 'Persistencia Standard', entityType: 'Database'}) SET d.motor = 'PostgreSQL Aurora (AWS)', d.acceso = 'JdbcTemplate - NO JPA/Hibernate', d.queries = 'Centralizadas en ConstantsQuery.java - no hardcodear SQL', d.paginacion = 'Cursor-based por PK para tablas con mas de 500 registros - NO OFFSET/LIMIT', d.rowMappers = 'En paquete mapper/ cuando son complejos 20+ columnas o reutilizados', d.cache = 'Cache con TTL en repositorio para datos de configuracion leidos en cada mensaje', d.auditoria = 'AuditoriaXxxRepository para trazabilidad de todas las operaciones', d.errorHandling = 'Envolver DataAccessException en XxxPersistenceException'"

run "Relacion Standard->DB" \
  "MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (d:Entity {name: 'Persistencia Standard', entityType: 'Database'}) MERGE (r)-[:DEFINE]->(d)"

# =============================================================
echo "[7/8] Convenciones y reglas DO/DONT..."
run "Convenciones naming" \
  "MERGE (c:Entity {name: 'Convenciones Naming', entityType: 'NamingConventions'}) SET c.interfaces = 'XxxService XxxProcessor XxxRepository', c.implementaciones = 'XxxServiceImpl XxxProcessorImpl con @Service', c.dtos = 'XxxInputDto XxxOutputDto XxxRequestDto XxxResponseDto', c.listeners = 'XxxKafkaListener con @Component', c.configs = 'XxxConfig XxxKafkaConfig XxxClientConfig con @Configuration', c.exceptions = 'XxxException XxxClientException XxxPersistenceException', c.metodos = 'procesarXxx() consultarXxx() registrarXxx() para servicios - findById() findAll() insert() update() para repos - consumir() enviarMensaje() para kafka', c.javadoc = 'OBLIGATORIO en todos los metodos - debe explicar objetivo o funcionamiento del metodo'"

run "Convenciones logging" \
  "MERGE (l:Entity {name: 'Convenciones Logging', entityType: 'LoggingConventions'}) SET l.error = 'ERROR: errores que requieren investigacion inmediata', l.warn = 'WARN: situaciones anormales pero recuperables', l.info = 'INFO: inicio/fin procesamiento publicacion Kafka', l.debug = 'DEBUG: payloads queries SQL - solo en local', l.contexto = 'Incluir siempre idProceso y codigoSucursal en logs', l.emojis = 'Recomendado: check exito X error advertencia sobre mensaje-recibido mensaje-enviado rojo-circuit-breaker'"

run "Reglas DO" \
  "MERGE (do_node:Entity {name: 'Reglas DO', entityType: 'BestPractices'}) SET do_node.r1 = 'Usar service interfaces: siempre definir interface antes de implementacion', do_node.r2 = 'Usar Lombok: @Data @Builder @RequiredArgsConstructor @Slf4j', do_node.r3 = 'Logging apropiado: DEBUG local INFO produccion - incluir idProceso y codigoSucursal', do_node.r4 = 'Tests unitarios: 95% cobertura minima con JaCoCo', do_node.r5 = 'Excepciones custom por dominio: XxxException XxxClientException XxxPersistenceException', do_node.r6 = 'JdbcTemplate para PostgreSQL - nunca JPA/Hibernate', do_node.r7 = 'Factory Pattern para Kafka: extender KafkaConfig base', do_node.r8 = 'Naming DTOs consistente: InputDto OutputDto RequestDto ResponseDto', do_node.r9 = 'AckMode MANUAL en Kafka para at-least-once', do_node.r10 = 'max.poll.records=1 para backpressure', do_node.r11 = 'enable.metrics.push=false CRITICO para evitar OOM en MSK', do_node.r12 = 'ErrorHandlingDeserializer como wrapper de JsonDeserializer', do_node.r13 = 'Paginacion cursor-based para tablas con mas de 500 registros', do_node.r14 = 'Cache con TTL en repositorio para datos de configuracion', do_node.r15 = 'Envio Kafka sincrono en dominios financieros', do_node.r16 = 'Timeout explicito 3s en PostgresHealthIndicator', do_node.r17 = 'RowMappers en paquete mapper/ para 20+ columnas o reutilizados', do_node.r18 = 'Clasificar errores listener: deterministas a DLQ inmediato vs infraestructura re-throw', do_node.r19 = 'NonRetryableClientDataException para errores irrecuperables hacia DLQ sin reintentos', do_node.r20 = 'Ajustar max.poll.interval.ms segun tiempo real de procesamiento con AtomicLong', do_node.r21 = 'JavaDoc OBLIGATORIO en todos los metodos explicando objetivo o funcionamiento'"

run "Reglas DONT" \
  "MERGE (dont:Entity {name: 'Reglas DONT', entityType: 'AntiPatterns'}) SET dont.r1 = 'No duplicar configuracion Kafka: extender la clase base KafkaConfig', dont.r2 = 'No crear nuevos error handlers Kafka sin extender el de KafkaConfig', dont.r3 = 'No modificar NotificationMessageDto sin coordinacion cross-team', dont.r4 = 'No usar JPA/Hibernate: arquitectura basada en JDBC puro con JdbcTemplate', dont.r5 = 'No hacer bypass del service layer: siempre usar las interfaces', dont.r6 = 'No usar OFFSET/LIMIT para paginacion sobre tablas grandes: cursor-based por PK', dont.r7 = 'No crear multiples consumer groups para el mismo topic sin justificacion documentada', dont.r8 = 'No omitir enable.metrics.push=false: provoca OOM progresivo en MSK en produccion', dont.r9 = 'No hardcodear SQL fuera de ConstantsQuery', dont.r10 = 'No ignorar max.poll.interval.ms: si procesamiento supera el intervalo Kafka expulsa al consumer', dont.r11 = 'No usar cache sin TTL en repositorios: datos congelados generan bugs dificiles de diagnosticar', dont.r12 = 'No enviar a DLQ desde listener para errores de infraestructura: dejar que KafkaConfig maneje reintentos', dont.r13 = 'No omitir JavaDoc en metodos publicos'"

run "Relaciones Standard->Convenciones" \
  "MERGE (r:Entity {name: 'Standard KLAP BYSF', entityType: 'Standard'}) MERGE (c:Entity {name: 'Convenciones Naming', entityType: 'NamingConventions'}) MERGE (l:Entity {name: 'Convenciones Logging', entityType: 'LoggingConventions'}) MERGE (do_node:Entity {name: 'Reglas DO', entityType: 'BestPractices'}) MERGE (dont:Entity {name: 'Reglas DONT', entityType: 'AntiPatterns'}) MERGE (r)-[:DEFINE]->(c) MERGE (r)-[:DEFINE]->(l) MERGE (r)-[:DEFINE]->(do_node) MERGE (r)-[:DEFINE]->(dont)"

# =============================================================
echo "[8/8] Templates de codigo (estructuras)..."
run "Template KafkaConfig" \
  "MERGE (t:Entity {name: 'Template KafkaConfig Dominio', entityType: 'CodeTemplate'}) SET t.clase = 'XxxKafkaConfig extends KafkaConfig', t.anotaciones = '@Configuration @EnableKafka', t.beans = 'xxxConsumerFactory() + xxxListenerContainerFactory() + xxxProducerFactory() + xxxKafkaTemplate() + notificationKafkaTemplate() + dlqKafkaTemplate()', t.patron = 'Extender KafkaConfig base y usar factory methods protegidos', t.nota = 'NO duplicar logica de configuracion: usar createConsumerFactory() createProducerFactory() createKafkaTemplate() createListenerContainerFactoryWithDlq()'"

run "Template KafkaListener" \
  "MERGE (t:Entity {name: 'Template KafkaListener', entityType: 'CodeTemplate'}) SET t.clase = 'XxxKafkaListener', t.anotaciones = '@Component @Slf4j @RequiredArgsConstructor', t.metodo = 'consumir(@Payload XxxInputDto mensaje, @Header topic/partition/offset, Acknowledgment)', t.flujo = '1-validarMensaje 2-xxxProcessor.procesarXxx 3-acknowledgment.acknowledge 4-trackear tiempo procesamiento', t.errorDeterminista = 'IllegalArgumentException o IllegalStateException -> enviarADlqManual + acknowledge', t.errorInfraestructura = 'Exception generica -> re-throw para que KafkaConfig maneje reintentos automaticos', t.circuitBreaker = 'AtomicInteger consecutiveFailures, threshold=10, reset timeout=60s', t.tracking = 'AtomicLong maxProcessingTimeMs para ajustar max.poll.interval.ms'"

run "Template Processor" \
  "MERGE (t:Entity {name: 'Template Processor', entityType: 'CodeTemplate'}) SET t.interface = 'XxxProcessor en services/', t.impl = 'XxxProcessorImpl en services/impl/ con @Service @Slf4j @RequiredArgsConstructor', t.patron = 'Saga: 1-validar 2-consultar API externa 3-procesar logica negocio 4-persistir DB 5-publicar Kafka output 6-publicar notificacion', t.compensacion = 'Fallos en pasos 2-6: auditar como PENDIENTE o ERROR para retry manual', t.nota = 'Orquestador principal - coordina todos los servicios del dominio'"

run "Template Repository" \
  "MERGE (t:Entity {name: 'Template Repository', entityType: 'CodeTemplate'}) SET t.clase = 'XxxRepository con @Repository @RequiredArgsConstructor @Slf4j', t.dependencia = 'JdbcTemplate (inyeccion por constructor)', t.queries = 'Siempre usar ConstantsQuery.XXX - NUNCA hardcodear SQL inline', t.paginacion = 'Cursor-based: WHERE id > :lastId ORDER BY id LIMIT :pageSize para tablas grandes', t.rowMapper = 'En paquete mapper/ si tiene 20+ columnas o se reutiliza en multiples metodos', t.cache = 'Cache con TTL para datos de configuracion leidos frecuentemente', t.errores = 'Envolver DataAccessException en XxxPersistenceException'"

run "Template WebClient" \
  "MERGE (t:Entity {name: 'Template WebClient', entityType: 'CodeTemplate'}) SET t.config = 'XxxClientConfig @Configuration con WebClient Bean y timeout explicito', t.cliente = 'XxxClient @Component con WebClient inyectado', t.retry = 'Retry.fixedDelay(maxAttempts, backoffDelay) - NO reintenta IllegalArgumentException', t.errores = 'onStatus 4xx -> XxxClientException con statusCode + body / 5xx -> igual', t.envio = 'SIEMPRE .block() sincrono para dominios financieros', t.timeout = 'CONNECT_TIMEOUT + responseTimeout + ReadTimeoutHandler + WriteTimeoutHandler'"

run "Template Excepciones" \
  "MERGE (t:Entity {name: 'Template Excepciones', entityType: 'CodeTemplate'}) SET t.base = 'XxxException extends RuntimeException con constructores String y String+Throwable', t.cliente = 'XxxClientException extends XxxException con statusCode + responseBody', t.persistencia = 'XxxPersistenceException extends XxxException', t.nonRetryable = 'NonRetryableClientDataException para errores de datos irrecuperables DLQ sin reintentos', t.jerarquia = 'RuntimeException -> KafkaMessageException / JsonProcessingException / XxxException -> XxxClientException / XxxPersistenceException'"

run "Template Testing" \
  "MERGE (t:Entity {name: 'Template Testing', entityType: 'CodeTemplate'}) SET t.framework = '@ExtendWith(MockitoExtension.class) JUnit 5 + Mockito + AssertJ', t.estructura = '@Mock dependencias + @InjectMocks sujeto + @Captor para verificar argumentos', t.patron = 'Arrange (setup mocks) + Act (ejecutar) + Assert (verificar resultado y verificar interacciones)', t.cobertura = '95% minimo con JaCoCo - fallar build si no se alcanza', t.webClient = 'MockWebServer para tests de XxxClient - simular respuestas HTTP', t.nombrado = 'testScenarioExitoso() testScenarioConError() testScenarioConValidacion()'"

run "Template OpenAPI" \
  "MERGE (t:Entity {name: 'Template OpenAPI', entityType: 'CodeTemplate'}) SET t.clase = 'OpenApiConfig @Configuration en global/config/', t.bean = '@Bean OpenAPI con Info: title + version + description', t.nota = 'Disponible en /swagger-ui.html y /v3/api-docs en perfiles local y develop'"

run "Relaciones Standard->Templates" \
  "MATCH (r:Entity {name: 'Standard KLAP BYSF'}) MATCH (t:Entity) WHERE t.entityType = 'CodeTemplate' MERGE (r)-[:PROVEE]->(t)"

# ── Verificacion final ─────────────────────────────────────────
echo ""
echo "Verificacion del grafo:"
curl -s \
  -u "${NEO4J_USER}:${NEO4J_PASS}" \
  "${BASE_URL}/db/${USE_DB}/tx/commit" \
  -H "Content-Type: application/json" \
  -d '{"statements":[{"statement":"MATCH (n:Entity) RETURN n.entityType as tipo, count(n) as total ORDER BY total DESC"}]}' \
  | grep -o '"row":\[[^]]*\]' | sed 's/"row":\[//g; s/\]//g; s/,/ — /g; s/"//g' \
  | while read -r line; do echo "  $line"; done

echo ""
echo "====================================================="
echo "  [OK] Arquitectura de referencia cargada"
echo ""
echo "  Nodos creados:"
echo "  - Standard KLAP BYSF (raiz)"
echo "  - Stack Tecnologico + Dependencias"
echo "  - Arquitectura Capas + Principios"
echo "  - Estructura Paquetes"
echo "  - Kafka Config + Topics"
echo "  - Persistencia Standard"
echo "  - Convenciones Naming + Logging"
echo "  - Reglas DO (21 reglas) + DONT (13 reglas)"
echo "  - Templates: Kafka, Listener, Processor,"
echo "    Repository, WebClient, Excepciones,"
echo "    Testing, OpenAPI"
echo "====================================================="
echo ""
echo "Verifica en: http://${NEO4J_HOST}:${NEO4J_PORT}"
echo "Query: MATCH (n:Entity) RETURN n"
echo ""
