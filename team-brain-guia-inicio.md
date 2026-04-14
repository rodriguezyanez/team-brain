# Team Brain — Guía de inicio

> Memoria compartida con Neo4j + Claude Code para equipos de desarrollo.

---

## ¿Qué es Team Brain?

Team Brain es un grafo de conocimiento compartido que vive en Neo4j y se conecta a Claude Code vía MCP (Model Context Protocol). Permite que todos los devs del equipo compartan el mismo contexto: decisiones técnicas, bugs resueltos, patrones, convenciones y arquitectura del proyecto.

**Resultado:** Claude recuerda lo que el equipo ha aprendido y no repite los mismos errores ni contradice decisiones ya tomadas.

---

## Requisitos

| | Linux / macOS | Windows |
|---|---|---|
| **Docker** | Docker Engine o Docker Desktop | Docker Desktop |
| **Node.js** | >= 18 | >= 18 |
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` | `npm install -g @anthropic-ai/claude-code` |
| **curl** | Incluido en el sistema | Incluido en Windows 10/11 |
| **PowerShell** | — | >= 5.1 (incluido en Windows 10/11) |

---

## Archivos del proyecto

El paquete incluye scripts para ambos sistemas. Colócalos en un directorio de tu elección:

```
team-brain/
├── docker-compose.yml      ← mismo archivo para ambos sistemas
├── CLAUDE.md               ← mismo archivo para ambos sistemas
│
├── init-brain.sh           ← inicialización  (Linux/macOS)
├── backup.sh               ← backup/restore  (Linux/macOS)
│
├── init-brain.bat          ← inicialización  (Windows, CMD)
├── init-brain.ps1          ← inicialización  (Windows, PowerShell)
├── backup.bat              ← backup/restore  (Windows, CMD)
├── backup.ps1              ← backup/restore  (Windows, PowerShell)
├── brain.bat               ← comandos rápidos (Windows, CMD)
└── brain.ps1               ← comandos rápidos (Windows, PowerShell)
```

> **Windows:** Los `.bat` funcionan con doble clic o desde CMD sin configuración extra.
> Los `.ps1` son más robustos. Si PowerShell bloquea la ejecución, ejecuta esto una sola vez como administrador:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```

---

## Instalador unificado (recomendado — todos los SO)

Hacé todo el setup en **un solo comando**:

**Windows (CMD)**
```bat
cd team-brain
setup.bat
```

**Windows (PowerShell)**
```powershell
cd team-brain
.\setup.ps1
```

**Linux / macOS**
```bash
cd team-brain
chmod +x setup.sh && ./setup.sh
```

El instalador hace automáticamente:
1. Verifica prerequisitos (Docker, Node.js, Claude Code, curl)
2. Detecta la password desde `docker-compose.yml`
3. Levanta Neo4j con `docker compose up -d`
4. Espera que Neo4j esté listo e inicializa la base de datos
5. Carga la arquitectura de referencia KLAP BYSF
6. Registra el MCP `team-brain` en Claude Code con `--scope user`
7. Copia `CLAUDE.md` a `~/.claude/CLAUDE.md` (Linux/macOS) o `%USERPROFILE%\.claude\CLAUDE.md` (Windows)

Al finalizar muestra un resumen con el estado de cada paso.

> Si preferís hacerlo paso a paso, seguí la guía manual a continuación.

---

## Setup del servidor (una vez, en la máquina compartida)

### 1. Cambiar la password

Edita `docker-compose.yml` y reemplaza:

```yaml
NEO4J_AUTH: neo4j/team-brain-2025
```

Por una password segura. Usa esa misma password en todos los pasos siguientes.

### 2. Levantar Neo4j

**Linux / macOS**
```bash
cd team-brain/
docker compose up -d
```

**Windows (CMD)**
```bat
cd team-brain
brain.bat up
```

**Windows (PowerShell)**
```powershell
cd team-brain
.\brain.ps1 up
```

Verificar que levantó correctamente:

**Linux / macOS**
```bash
docker compose ps
docker compose logs neo4j --tail=20
# Esperar el mensaje: Started.
```

**Windows**
```bat
brain.bat status
brain.bat logs
```

Abrir el browser en **http://localhost:7474** → login con `neo4j` y tu password.

**Windows (atajo):**
```bat
brain.bat browser
```

### 3. Inicializar la base de datos

Ejecutar **solo una vez**. Crea la DB `memory`, los constraints, los índices y los nodos base del equipo.

**Linux / macOS**
```bash
chmod +x init-brain.sh
./init-brain.sh
```

**Windows (CMD)**
```bat
init-brain.bat
```

**Windows (PowerShell — recomendado)**
```powershell
.\init-brain.ps1

# Si Neo4j está en otra máquina o usas password diferente:
.\init-brain.ps1 -Host 192.168.1.50 -Password "mi-password"
```

---

## Setup por dev (cada miembro del equipo)

### 1. Registrar el MCP en Claude Code

**Linux / macOS**
```bash
claude mcp add-json "team-brain" '{
  "command": "npx",
  "args": ["-y", "@jovanhsu/mcp-neo4j-memory-server"],
  "env": {
    "NEO4J_URI": "bolt://localhost:7687",
    "NEO4J_USER": "neo4j",
    "NEO4J_PASSWORD": "TU_PASSWORD_AQUI",
    "NEO4J_DATABASE": "memory"
  }
}'
```

**Windows (CMD — forma rápida)**
```bat
brain.bat mcp
```

**Windows (PowerShell — forma rápida)**
```powershell
.\brain.ps1 mcp
```

**Windows (PowerShell — manual, si necesitas cambiar la password)**
```powershell
claude mcp add-json "team-brain" '{"command":"npx","args":["-y","@jovanhsu/mcp-neo4j-memory-server"],"env":{"NEO4J_URI":"bolt://localhost:7687","NEO4J_USER":"neo4j","NEO4J_PASSWORD":"TU_PASSWORD_AQUI","NEO4J_DATABASE":"memory"}}'
```

> Si Neo4j está en otra máquina de la red, reemplaza `localhost` por la IP de esa máquina.

### 2. Confirmar que quedó registrado

```bash
claude mcp list
# Deberías ver: team-brain
```

*(Mismo comando en Linux, macOS y Windows)*

### 3. Instalar el CLAUDE.md

**Linux / macOS**
```bash
# Global (recomendado — aplica en todos los proyectos)
cp CLAUDE.md ~/.claude/CLAUDE.md

# O solo para un proyecto específico
cp CLAUDE.md /ruta/a/tu/proyecto/CLAUDE.md
```

**Windows (CMD)**
```bat
:: Crear directorio si no existe y copiar
mkdir %USERPROFILE%\.claude 2>nul
copy CLAUDE.md %USERPROFILE%\.claude\CLAUDE.md
```

**Windows (PowerShell)**
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude" | Out-Null
Copy-Item CLAUDE.md "$env:USERPROFILE\.claude\CLAUDE.md"
```

### 4. Probar que funciona

Abre Claude Code en cualquier directorio:

```bash
claude
```

Escribe:

```
¿Qué sabes del equipo?
```

Claude debería responder con `🧠 Consultando memoria del equipo...` y retornar los nodos base del grafo.

---

## Uso diario

### Al iniciar una sesión de trabajo

Pide contexto antes de tocar cualquier módulo:

```
Antes de que empiece a modificar el módulo de pagos,
revisa la memoria del equipo y dime qué decisiones
se han tomado sobre él.
```

### Durante el trabajo

Guarda decisiones importantes en el momento:

```
Guarda en la memoria del equipo que decidimos usar JWT
con refresh tokens para autenticación. El motivo fue que
necesitamos soporte para múltiples clientes móviles.
```

Documenta bugs y sus soluciones:

```
Guarda en memoria: bug resuelto hoy — el worker de Sidekiq
fallaba silenciosamente cuando el payload superaba 1MB.
Fix: comprimir con MessagePack antes de encolar.
Relaciona esto con el servicio NotificationWorker.
```

### Al terminar una sesión

```
Antes de cerrar, guarda en memoria un resumen de lo que
hicimos hoy: qué cambiamos, qué decidimos y qué quedó pendiente.
```

---

## Prompts de referencia

### Leer memoria

| Intención | Prompt |
|-----------|--------|
| Contexto general | `¿Qué sabes del equipo y del proyecto actual?` |
| Antes de tocar un módulo | `Revisa la memoria del equipo y dime qué decisiones se han tomado sobre [módulo].` |
| Buscar un fix previo | `¿El equipo ha tenido algún problema similar con [problema]? Busca en la memoria si hay un fix documentado.` |
| Convenciones del equipo | `¿Cuáles son las convenciones de naming y estructura de carpetas que usa el equipo?` |
| Validar una decisión | `Quiero usar [tecnología]. ¿Hay alguna decisión del equipo que deba considerar primero?` |

### Escribir en memoria

| Intención | Prompt |
|-----------|--------|
| Decisión técnica | `Guarda en memoria que decidimos [decisión]. El motivo fue [razón]. Se evaluó [alternativa] pero se descartó por [razón].` |
| Bug resuelto | `Guarda en memoria: bug resuelto — [descripción]. Fix: [solución]. Relaciona con [servicio].` |
| Nuevo servicio | `Guarda en memoria el servicio [nombre]: es [descripción], responsable de [función], se comunica con [dependencias].` |
| Patrón del equipo | `Documenta en memoria el patrón que usamos para [situación]: [descripción del patrón].` |
| Resumen de sesión | `Guarda un resumen de lo que hicimos hoy: qué cambiamos, qué decidimos y qué quedó pendiente.` |

### Flujos de equipo

| Intención | Prompt |
|-----------|--------|
| Onboarding | `Soy nuevo en el equipo. Consulta la memoria y dame un resumen completo: arquitectura, servicios, decisiones importantes y convenciones.` |
| Retrospectiva | `Busca en la memoria todo lo guardado esta semana y genera un resumen del sprint.` |
| Preparar code review | `Voy a revisar un PR del módulo de [módulo]. Busca en la memoria el contexto relevante antes de empezar.` |
| Auditar cobertura | `Lista todos los servicios en memoria y dime cuáles del repo faltan documentar en el grafo.` |

### Consultar Neo4j directamente

```cypher
-- Ver todo lo que hay en memoria
MATCH (e:Entity) RETURN e.name, e.entityType ORDER BY e.entityType

-- Ver todas las decisiones
MATCH (d:Entity {entityType: 'Decision'})
OPTIONAL MATCH (d)-[:HAS_OBSERVATION]->(o)
RETURN d.name, collect(o.content) AS observaciones

-- Ver relaciones entre entidades
MATCH (a)-[r]->(b) RETURN a.name, type(r), b.name LIMIT 50

-- Todo lo relacionado a un servicio
MATCH (e:Entity {name: 'nombre-servicio'})-[r*1..2]-(related)
RETURN e, r, related
```

> Ejecuta estas queries en **http://localhost:7474** o pídele a Claude Code que las ejecute por ti.

---

## Comandos operacionales

### Linux / macOS

```bash
docker compose up -d            # levantar
docker compose down             # detener (datos persisten)
docker compose logs -f neo4j    # ver logs en vivo
docker compose restart neo4j    # reiniciar
docker compose ps               # ver estado
```

### Windows — script `brain`

| Acción | CMD | PowerShell |
|--------|-----|------------|
| Levantar | `brain.bat up` | `.\brain.ps1 up` |
| Detener | `brain.bat down` | `.\brain.ps1 down` |
| Reiniciar | `brain.bat restart` | `.\brain.ps1 restart` |
| Ver estado | `brain.bat status` | `.\brain.ps1 status` |
| Ver logs | `brain.bat logs` | `.\brain.ps1 logs` |
| Abrir browser | `brain.bat browser` | `.\brain.ps1 browser` |
| Registrar MCP | `brain.bat mcp` | `.\brain.ps1 mcp` |

---

## Backup y restore

### Linux / macOS

```bash
./backup.sh backup                                              # crear backup
./backup.sh list                                               # listar backups
./backup.sh restore backups/neo4j-backup-20250410_120000.tar.gz  # restaurar
```

Backup automático diario (cron):
```bash
0 2 * * * cd /ruta/team-brain && ./backup.sh backup
```

### Windows (CMD)

```bat
backup.bat                                                         :: crear backup
backup.bat list                                                    :: listar
backup.bat restore backups\neo4j-backup-20250410_120000.tar.gz    :: restaurar
```

### Windows (PowerShell)

```powershell
.\backup.ps1                                                                              # crear backup
.\backup.ps1 -Action list                                                                 # listar
.\backup.ps1 -Action restore -File "backups\neo4j-backup-20250410_120000.tar.gz"         # restaurar
```

Backup automático en Windows con el Programador de tareas:
```powershell
$action  = New-ScheduledTaskAction -Execute "powershell.exe" `
           -Argument "-File C:\ruta\team-brain\backup.ps1" `
           -WorkingDirectory "C:\ruta\team-brain"
$trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
Register-ScheduledTask -TaskName "TeamBrainBackup" -Action $action -Trigger $trigger
```

---

## Troubleshooting

### Neo4j no levanta

**Linux / macOS**
```bash
docker compose logs neo4j | tail -30
```

**Windows**
```bat
brain.bat logs
```

Causas frecuentes: Docker Desktop no está corriendo, puerto ocupado, memoria insuficiente.

### Puerto 7687 ocupado

**Linux / macOS**
```bash
lsof -i :7687
```

**Windows (PowerShell)**
```powershell
netstat -ano | findstr :7687
```

Solución: cambia `"7687:7687"` por `"7688:7687"` en `docker-compose.yml` y actualiza `NEO4J_URI` en la config del MCP.

### MCP no conecta

```bash
docker compose ps       # verificar que Neo4j corre
claude mcp list         # verificar que el MCP está registrado
npx -y @jovanhsu/mcp-neo4j-memory-server   # test manual de conexión
```

*(Mismos comandos en todos los sistemas)*

### Claude no consulta la memoria

**Linux / macOS**
```bash
ls ~/.claude/CLAUDE.md
# Si no existe:
mkdir -p ~/.claude && cp CLAUDE.md ~/.claude/CLAUDE.md
```

**Windows (PowerShell)**
```powershell
Test-Path "$env:USERPROFILE\.claude\CLAUDE.md"
# Si devuelve False:
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude" | Out-Null
Copy-Item CLAUDE.md "$env:USERPROFILE\.claude\CLAUDE.md"
```

### Docker Desktop no inicia en Windows

Verificar que WSL 2 está instalado y actualizado:

```powershell
wsl --status
wsl --update
```

Si WSL no está instalado:
```powershell
wsl --install
# Reiniciar Windows después de la instalación
```

---

## Tipos de entidades recomendados

Usar estos tipos consistentemente en todo el equipo:

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| `Organization` | El equipo | Team |
| `Project` | Proyectos activos | proyecto-ecommerce |
| `Service` | Microservicios / APIs | billing-service |
| `Component` | Módulos internos | AuthModule |
| `Decision` | ADRs y decisiones técnicas | Usar PostgreSQL para transacciones |
| `Bug` / `Fix` | Problemas y soluciones | Timeout en Redis > 1MB |
| `Pattern` | Patrones de código del equipo | Error handling en Express |
| `Convention` | Estándares del equipo | Naming de ramas Git |
| `Developer` | Miembros del equipo | Juan Pablo — experto en Kafka |
| `Topic` | Áreas temáticas | Architecture, Security |

---

## Próximos pasos

Cuando quieras escalar el setup:

- [ ] Mover Neo4j a un servidor compartido en la red interna
- [ ] Configurar Tailscale para acceso remoto del equipo distribuido
- [ ] Crear usuarios con permisos diferenciados (read-only para devs junior)
- [ ] Montar Neo4j Aura (cloud managed) para equipos 100% remotos

---

*Team Brain — versión local · Linux, macOS y Windows · Abril 2025*
