@echo off
REM =============================================================
REM install-context7.bat — Registra Context7 MCP en Claude Code
REM Context7 provee documentacion en tiempo real de las librerias
REM del stack: Spring Boot 3.5.11, Kafka, Resilience4j, WebClient
REM =============================================================
setlocal

echo.
echo [INFO] === Instalando Context7 MCP en Claude Code ===
echo.

REM --- 1. Verificar claude CLI ---
where claude >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Claude CLI no encontrado. Instala Claude Code primero.
    echo [ERROR]   https://claude.ai/code
    exit /b 1
)
echo [OK] Claude CLI encontrado.

REM --- 2. Verificar npx ---
where npx >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] npx no encontrado. Instala Node.js primero.
    echo [ERROR]   https://nodejs.org
    exit /b 1
)
echo [OK] npx encontrado.

echo.
echo [INFO] Registrando Context7 MCP (scope: user)...
echo.

REM --- 3. Registrar el MCP ---
claude mcp add-json "context7" "{\"command\":\"npx\",\"args\":[\"-y\",\"@upstash/context7-mcp\"]}" --scope user

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Fallo el registro de Context7 MCP.
    echo [WARN]  Si ya existe, puede ignorarse este error.
    echo [WARN]  Verifica con: claude mcp list
    exit /b 1
)

echo.
echo [OK] Context7 MCP registrado correctamente.
echo.

REM --- 4. Verificar con mcp list ---
echo [INFO] MCPs registrados actualmente:
echo -----------------------------------------------
claude mcp list
echo -----------------------------------------------

echo.
echo [OK] === Instalacion completada ===
echo.
echo [INFO] Como usar Context7 en Claude Code:
echo.
echo   Agrega 'use context7' a tus prompts para obtener
echo   docs de la version exacta de las librerias del stack.
echo.
echo   Ejemplo:
echo   "use context7, como configuro Resilience4j 2.2.0
echo    con Spring Boot 3.5.11?"
echo.
echo   Otros ejemplos de uso:
echo   - "use context7, como uso WebClient con retry en Spring Boot 3.5.11?"
echo   - "use context7, configuracion de Kafka consumer con Spring 3.5.11"
echo   - "use context7, anotaciones de Resilience4j para circuit breaker"
echo.

endlocal
exit /b 0
