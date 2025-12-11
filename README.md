# Aula Exemplo Arquitetura SOA com Docker e k8s

Mini rede social (serviço de usuários e serviço de posts) exposta via API Gateway para demonstrar SOA/microserviços com service discovery (Consul), mensageria (Kafka) e observabilidade (Prometheus/Grafana). Orquestração em Docker Compose (manifests para k8s também inclusos).

## Recursos da arquitetura
- Service Discovery com Consul
- Circuit Breaker no API Gateway
- Kafka para comunicação assíncrona
- Prometheus para monitoramento
- Grafana provisionada
- Docker e/ou Kubernetes para orquestração

## Alterações recentes (esta sessão)
- Corrigido /metrics de usuarios-service e posts-service (import CONTENT_TYPE_LATEST).
- `scripts/check-metrics.bat` reescrito para PowerShell (lista jobs e métricas customizadas).
- `scripts/check-kafka.bat` simplificado para garantir `test-topic` e produzir/consumir mensagem de teste.
- Dependência cryptography já fixada em 41.0.7 nos requirements.
- Ajuste nos healthcheck do Consul, bind do Prometheus
## Execução rápida (Docker - Windows)
Pré-requisito: Docker Desktop ativo.
```bash
docker compose up -d
scripts\test-api.bat
scripts\check-metrics.bat
scripts\check-kafka.bat
```
Observação: o 400 no teste de usuário duplicado é esperado.

Endpoints: API http://localhost:8000, Consul http://localhost:8500, Prometheus http://localhost:9090, Grafana http://localhost:3000 (admin/admin).

## Execução passo a passo (Docker)
```bash
# Iniciar infraestrutura
scripts\start-docker.bat

# Aguardar serviços e criar tópicos Kafka
scripts\wait-for-services.bat
scripts\create-kafka-topics.bat

# Testar API
scripts\test-api.bat

# Configurar monitoramento / abrir interfaces
scripts\monitoring-setup.bat
scripts\monitor.bat
```

## k8s (não executado nesta sessão)
```bash
scripts/deploy-k8s.bat
scripts/port-forward.bat
scripts/test-api.bat
```

## Utilitários
```bash
scripts\check-services.bat
scripts\health-check.bat
scripts\check-metrics.bat
scripts\check-kafka.bat
scripts\stop-docker.bat
scripts\delete-k8s.bat
scripts\cleanup.bat
scripts\restart-docker.bat
```

## Testes manuais via cURL
```bash
curl -X POST http://localhost:8000/usuarios/registrar ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"john\",\"password\":\"secret\"}"

curl -X POST http://localhost:8000/usuarios/login ^
  -H "Content-Type: application/json" ^
  -d "{\"username\":\"john\",\"password\":\"secret\"}"

curl -X POST http://localhost:8000/posts ^
  -H "Content-Type: application/json" ^
  -d "{\"text\":\"Meu primeiro post\",\"user_id\":1}"

curl http://localhost:8000/posts
curl http://localhost:8000/metrics
curl http://localhost:8000/health
```
