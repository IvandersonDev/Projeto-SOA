@echo off
echo Verificando metricas disponiveis...

echo.
echo 1. Metricas de servicos:
powershell -NoLogo -NoProfile -Command ^
  "$resp = Invoke-RestMethod 'http://localhost:9090/api/v1/label/job/values';" ^
  "Write-Output 'Jobs monitorados:';" ^
  "foreach ($j in $resp.data) { '  ' + $j }"

echo.
echo 2. Metricas personalizadas:
powershell -NoLogo -NoProfile -Command ^
  "$metrics = 'requests_total','user_registrations_total','post_creations_total','request_latency_seconds_count';" ^
  "foreach ($m in $metrics) {" ^
  "  $res = Invoke-RestMethod \"http://localhost:9090/api/v1/query?query=$m\";" ^
  "  if ($res.data.result.Count -gt 0) {" ^
  "    Write-Output \"$m - OK ($($res.data.result.Count) series)\";" ^
  "  } else {" ^
  "    Write-Output \"$m - Nao encontrado\";" ^
  "  }" ^
  "}"

echo.
echo 3. Health checks:
powershell -NoLogo -NoProfile -Command ^
  "$res = Invoke-RestMethod 'http://localhost:9090/api/v1/query?query=up';" ^
  "Write-Output 'Status dos servicos:';" ^
  "foreach ($r in $res.data.result) {" ^
  "  $job = $r.metric.job;" ^
  "  $inst = $r.metric.instance;" ^
  "  $up = $r.value[1];" ^
  "  if ($up -eq '1') { $status = 'UP' } else { $status = 'DOWN' };" ^
  "  Write-Output ('  {0} {1} ({2})' -f $status, $job, $inst)" ^
  "}"

echo.
echo Verificacao de metricas concluida!
