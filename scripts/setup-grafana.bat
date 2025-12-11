@echo off
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
echo 2. Configurando datasource do Prometheus...
powershell -Command "
try {
    \$headers = @{
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
    }
    
    \$auth = 'admin:admin'
    \$bytes = [System.Text.Encoding]::UTF8.GetBytes(\$auth)
    \$base64 = [System.Convert]::ToBase64String(\$bytes)
    \$headers.Authorization = 'Basic ' + \$base64
    
    \$datasource = @{
        name = 'Prometheus'
        type = 'prometheus'
        access = 'proxy'
        url = 'http://prometheus:9090'
        isDefault = \$true
        jsonData = @{
            timeInterval = '15s'
            queryTimeout = '60s'
        }
    } | ConvertTo-Json
    
    \$response = Invoke-RestMethod -Uri 'http://localhost:3000/api/datasources' -Method Post -Headers \$headers -Body \$datasource
    Write-Host 'Datasource Prometheus configurado com sucesso! ID:' \$response.datasource.id -ForegroundColor Green
} catch {
    Write-Host 'Erro ao configurar datasource:' \$_.Exception.Message -ForegroundColor Red
    if (\$_.Exception.Response.StatusCode.Value__ -eq 409) {
        Write-Host 'Datasource ja existe, continuando...' -ForegroundColor Yellow
    }
}
"

echo.
echo 3. Importando dashboard padrao...
powershell -Command "
try {
    \$headers = @{
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
    }
    
    \$auth = 'admin:admin'
    \$bytes = [System.Text.Encoding]::UTF8.GetBytes(\$auth)
    \$base64 = [System.Convert]::ToBase64String(\$bytes)
    \$headers.Authorization = 'Basic ' + \$base64
    
    \$dashboardJson = @'
{
  "dashboard": {
    "id": null,
    "title": "SOA Architecture Monitoring",
    "tags": ["soa", "monitoring"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "HTTP Requests Total",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(requests_total)",
            "legendFormat": "Total Requests",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "unit": "short"
          }
        }
      },
      {
        "id": 2,
        "title": "Request Latency",
        "type": "timeseries",
        "targets": [
          {
            "expr": "rate(request_latency_seconds_sum[5m]) / rate(request_latency_seconds_count[5m])",
            "legendFormat": "Avg Latency",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "fieldConfig": {
          "defaults": {
            "unit": "s",
            "color": {"mode": "palette-classic"}
          }
        }
      },
      {
        "id": 3,
        "title": "User Registrations",
        "type": "stat",
        "targets": [
          {
            "expr": "user_registrations_total",
            "legendFormat": "Registrations",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 8, "x": 0, "y": 8},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"}
          }
        }
      },
      {
        "id": 4,
        "title": "Post Creations",
        "type": "stat",
        "targets": [
          {
            "expr": "post_creations_total",
            "legendFormat": "Posts Created",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 8, "x": 8, "y": 8},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"}
          }
        }
      },
      {
        "id": 5,
        "title": "Service Health",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=~\"api-gateway|usuarios-service|posts-service\"}",
            "legendFormat": "{{job}}",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 8, "x": 16, "y": 8},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "steps": [
                {"color": "red", "value": null},
                {"color": "green", "value": 1}
              ]
            },
            "unit": "short"
          }
        }
      }
    ],
    "time": {"from": "now-1h", "to": "now"},
    "timepicker": {},
    "templating": {"list": []},
    "refresh": "10s",
    "schemaVersion": 35,
    "version": 1
  },
  "folderId": 0,
  "overwrite": true
}
'@

    \$dashboard = \$dashboardJson | ConvertFrom-Json
    
    \$response = Invoke-RestMethod -Uri 'http://localhost:3000/api/dashboards/db' -Method Post -Headers \$headers -Body (\$dashboard | ConvertTo-Json -Depth 10)
    Write-Host 'Dashboard SOA Architecture importado com sucesso!' -ForegroundColor Green
    Write-Host '   URL: http://localhost:3000' \$response.url -ForegroundColor Cyan
} catch {
    Write-Host 'Erro ao importar dashboard:' \$_.Exception.Message -ForegroundColor Red
}
"

echo.
echo 4. Configuracao do Grafana concluida!
echo.
echo Acesse: http://localhost:3000
echo Usuario: admin
echo Senha: admin
echo.