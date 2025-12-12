@echo off
setlocal
echo Verificando status do Kafka...

echo.
echo 1. Verificando containers...
docker ps --filter "name=kafka" --format "table {{.Names}}\t{{.Status}}"

echo.
echo 2. Verificando saude do Kafka...
docker inspect kafka --format "{{json .State.Health }}" | python -c "import json,sys; obj=json.load(sys.stdin); print(f'Status: {obj.get('Status','desconhecido')}')"

echo.
echo 3. Garantindo topico de teste...
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --create --if-not-exists --topic test-topic --partitions 1 --replication-factor 1 >nul 2>&1
if %errorlevel% neq 0 (
    echo Aviso: nao consegui criar test-topic (pode ja existir)
)

echo.
echo 4. Listando topicos...
docker exec kafka kafka-topics --bootstrap-server localhost:29092 --list

echo.
echo 5. Verificando detalhes dos topicos principais...
for %%t in (health-check post-events service-logs user-events test-topic) do (
    echo Topico: %%t
    docker exec kafka kafka-topics --bootstrap-server localhost:29092 --topic %%t --describe
)

echo.
echo 6. Testando producao de mensagem...
docker exec kafka bash -lc "printf 'hello-from-check\n' | kafka-console-producer --bootstrap-server localhost:29092 --topic test-topic --producer-property acks=1" >nul 2>&1
if %errorlevel% neq 0 (
    echo Erro ao produzir mensagem de teste
)

echo.
echo 7. Testando consumo de mensagem...
docker exec kafka kafka-console-consumer --bootstrap-server localhost:29092 --topic test-topic --from-beginning --max-messages 1 --timeout-ms 5000

if %errorlevel% equ 0 (
    echo Kafka esta consumindo corretamente
) else (
    echo Kafka com problemas de consumo
)

echo.
echo Verificacao do Kafka concluida!
endlocal
