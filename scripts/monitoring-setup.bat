@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

echo ====================================
echo    CONFIGURACAO DE MONITORAMENTO
echo ====================================

echo.
echo 1. Verificando servicos de monitoramento...
docker ps --filter "name=prometheus" --format "table {{.Names}}\t{{.Status}}"
docker ps --filter "name=grafana" --format "table {{.Names}}\t{{.Status}}"

echo.
echo 2. Configurando Grafana...
call "%SCRIPT_DIR%setup-grafana.bat"

echo.
echo 3. Verificando metricas no Prometheus...
curl -s "http://localhost:9090/api/v1/query?query=up" | python -c "import json,sys; data=json.load(sys.stdin); results=data.get('data', {}).get('result', []); print('\n'.join([('OK ' if r['value'][1]=='1' else 'ERROR ')+r['metric'].get('job','unknown')+': '+r['value'][1] for r in results]) if results else 'Nenhuma metrica encontrada')"

echo.
echo 4. URLs de Monitoramento:
echo.
echo Prometheus:  http://localhost:9090
echo Grafana:     http://localhost:3000
echo    Usuario:     admin
echo    Senha:       admin
echo.
echo Dashboard:   http://localhost:3000/d/soa-monitoring
echo.

echo 5. Testando consultas Prometheus...
echo.
echo "Consultas exemplo:"
echo "  requests_total"
echo "  rate(requests_total[5m])"
echo "  up{job='api-gateway'}"
echo "  user_registrations_total"
echo.

echo Configuracao de monitoramento concluida!
pause
endlocal
