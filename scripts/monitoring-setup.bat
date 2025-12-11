@echo off
echo ====================================
echo    CONFIGURACAO DE MONITORAMENTO
echo ====================================

echo.
echo 1. Verificando servicos de monitoramento...
docker ps --filter "name=prometheus" --format "table {{.Names}}\t{{.Status}}"
docker ps --filter "name=grafana" --format "table {{.Names}}\t{{.Status}}"

echo.
echo 2. Configurando Grafana...
call scripts/setup-grafana.bat

echo.
echo 3. Verificando metricas no Prometheus...
curl -s "http://localhost:9090/api/v1/query?query=up" | python -c "
import json, sys
data = json.load(sys.stdin)
if 'data' in data and 'result' in data['data']:
    for result in data['data']['result']:
        job = result['metric'].get('job', 'unknown')
        value = result['value'][1]
        status = 'OK' if value == '1' else 'ERROR'
        print(f'{status} {job}: {value}')
else:
    print('Nenhuma metrica encontrada')
"

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