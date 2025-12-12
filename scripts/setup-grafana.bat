@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

echo Configurando Grafana automaticamente...

echo.
echo 1. Aguardando Grafana ficar disponivel...
:check_grafana
curl -s -o nul -w "%%{http_code}" http://localhost:3000/api/health
if %errorlevel% neq 0 (
    echo Grafana ainda nao esta pronto, aguardando...
    timeout 5
    goto :check_grafana
)
echo Grafana esta respondendo

echo.
echo 2. Configurando datasource do Prometheus e importando dashboard...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup-grafana.ps1"
if %errorlevel% neq 0 (
    echo Falha ao configurar Grafana.
    exit /b 1
)

echo.
echo 3. Configuracao do Grafana concluida!
echo.
echo Acesse: http://localhost:3000
echo Usuario: admin
echo Senha: admin
echo.
endlocal
