@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%.."
title SOA Architecture - Startup Completo
echo ===============================================
echo    INICIALIZACAO COMPLETA DA ARQUITETURA SOA
echo ===============================================

echo.
echo FASE 1: Iniciando infraestrutura...
call "%SCRIPT_DIR%start-docker.bat"

echo.
echo FASE 2: Aguardando servicos...
call "%SCRIPT_DIR%wait-for-services.bat"

echo.
echo FASE 3: Criando topicos Kafka...
call "%SCRIPT_DIR%create-kafka-topics.bat"

echo.
echo FASE 4: Verificando Kafka...
call "%SCRIPT_DIR%check-kafka.bat"

echo.
echo FASE 5: Verificando saude do sistema...
call "%SCRIPT_DIR%health-check.bat"

echo.
echo FASE 6: Testando API...
call "%SCRIPT_DIR%test-api.bat"

echo.
echo FASE 7: Configurando monitoramento...
echo Configurando datasource do Prometheus no Grafana...
call "%SCRIPT_DIR%monitoring-setup.bat"
timeout 10

echo.
echo FASE 8: Abrindo interfaces...
start "" "http://localhost:8500"
timeout 2
start "" "http://localhost:9090"
timeout 2
start "" "http://localhost:3000"

echo.
echo ===============================================
echo         INICIALIZACAO CONCLUIDA!
echo ===============================================
echo.
echo URLs de acesso:
echo.
echo API Gateway:    http://localhost:8000
echo Consul UI:      http://localhost:8500
echo Prometheus:     http://localhost:9090
echo Grafana:        http://localhost:3000
echo    Usuario: admin
echo    Senha:   admin
echo.
echo Para testar a API: test-api.bat
echo Para parar: stop-docker.bat
echo.
pause
popd
