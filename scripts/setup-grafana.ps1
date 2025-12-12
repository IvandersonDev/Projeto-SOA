$ErrorActionPreference = 'Stop'

function Get-Creds {
    $user = $env:GRAFANA_USER
    if (-not $user) { $user = $env:GF_SECURITY_ADMIN_USER }
    if (-not $user) { $user = 'admin' }

    $pass = $env:GRAFANA_PASS
    if (-not $pass) { $pass = $env:GF_SECURITY_ADMIN_PASSWORD }
    if (-not $pass) { $pass = 'admin' }

    return @{ User = $user; Pass = $pass }
}

function Get-AuthHeaders {
    param([string]$User, [string]$Pass)

    $auth = "$($User):$($Pass)"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($auth)
    $base64 = [System.Convert]::ToBase64String($bytes)

    return @{
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
        'Authorization' = 'Basic ' + $base64
    }
}

function Configure-Datasource {
    param([hashtable]$Headers, [string]$User)

    $datasource = @{
        name      = 'Prometheus'
        type      = 'prometheus'
        access    = 'proxy'
        url       = 'http://prometheus:9090'
        isDefault = $true
        jsonData  = @{
            timeInterval = '15s'
            queryTimeout = '60s'
        }
    }

    try {
        $response = Invoke-RestMethod -Uri 'http://localhost:3000/api/datasources' -Method Post -Headers $Headers -Body ($datasource | ConvertTo-Json -Depth 5)
        Write-Host "Datasource Prometheus configurado. ID: $($response.datasource.id)" -ForegroundColor Green
    } catch {
        $code = $_.Exception.Response.StatusCode.Value__
        if ($code -eq 409) {
            Write-Host 'Datasource ja existe, continuando...' -ForegroundColor Yellow
        } elseif ($code -eq 401) {
            Write-Host ('Credenciais Grafana rejeitadas para o usuario "{0}". Ajuste GRAFANA_USER/GRAFANA_PASS ou GF_SECURITY_ADMIN_USER/GF_SECURITY_ADMIN_PASSWORD e rode novamente.' -f $User) -ForegroundColor Red
            throw
        } else {
            Write-Host 'Erro ao configurar datasource:' $_.Exception.Message -ForegroundColor Red
            throw
        }
    }
}

function Import-Dashboard {
    param([hashtable]$Headers)

    $dashboardJson = @'
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

    try {
        $dashboard = $dashboardJson | ConvertFrom-Json
        $response = Invoke-RestMethod -Uri 'http://localhost:3000/api/dashboards/db' -Method Post -Headers $Headers -Body ($dashboard | ConvertTo-Json -Depth 10)
        Write-Host 'Dashboard SOA Architecture importado com sucesso!' -ForegroundColor Green
        if ($response.url) {
            Write-Host ('   URL: http://localhost:3000{0}' -f $response.url) -ForegroundColor Cyan
        }
    } catch {
        Write-Host 'Erro ao importar dashboard:' $_.Exception.Message -ForegroundColor Red
        throw
    }
}

$creds = Get-Creds
$headers = Get-AuthHeaders -User $creds.User -Pass $creds.Pass
Configure-Datasource -Headers $headers -User $creds.User
Import-Dashboard -Headers $headers
