# Private VPN Project

Monorepo scaffold for subscription tracking around private VPN access.

Public repository: <https://github.com/Nehoko/private-vpn-project>

## Stack

- `payment-ingest`: Deno/TypeScript webhook intake for Telegram wallet or bridge adapter
- `subscription-service`: Deno/TypeScript subscriber state + renewal logic
- `api-gateway`: Deno/TypeScript admin bootstrap + delta API
- `expiry-worker`: Deno/TypeScript daily due-date scan
- `push-publisher`: Deno/TypeScript APNs push sender
- `admin-macos`: native SwiftUI macOS app
- `postgres`: source of truth
- `redpanda`: Kafka-compatible event bus

## Repo shape

- `apps/` runnable applications
- `packages/contracts` shared event/API contracts
- `packages/kafka` shared Kafka helpers
- `infra/compose` local SQL/bootstrap assets
- `docs/joplin` synthesized wiki pages mirrored into Joplin

## Local run

1. Copy environment file.

```bash
cp .env.example .env
```

2. Start local stack.

```bash
docker compose up --build -d
```

3. Check health.

```bash
curl -s http://127.0.0.1:8080/health
curl -s http://127.0.0.1:8081/health
curl -s http://127.0.0.1:8082/health
curl -s http://127.0.0.1:8083/health
curl -s http://127.0.0.1:8084/health
```

4. Run macOS admin app.

```bash
cd apps/admin-macos
swift run PrivateVPNAdmin
```

App now shows first-launch popup for backend URL and admin token, so shell env vars are optional.

## Compose example

```yaml
services:
  redpanda:
    image: redpandadata/redpanda:v24.1.13
    command:
      - redpanda
      - start
      - --overprovisioned
      - --smp
      - "1"
      - --memory
      - 512M
      - --reserve-memory
      - 0M
      - --node-id
      - "0"
      - --check=false
      - --kafka-addr
      - PLAINTEXT://0.0.0.0:9092
      - --advertise-kafka-addr
      - PLAINTEXT://redpanda:9092

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

  api-gateway:
    build:
      context: .
      dockerfile: apps/api-gateway/Dockerfile
    env_file: .env
    depends_on:
      - redpanda
      - postgres
    ports:
      - "8080:8080"
```

Full stack lives in [`docker-compose.yml`](./docker-compose.yml).

## Environment example

```env
POSTGRES_DB=private_vpn
POSTGRES_USER=private_vpn
POSTGRES_PASSWORD=private_vpn
DATABASE_URL=postgres://private_vpn:private_vpn@postgres:5432/private_vpn
KAFKA_BROKERS=redpanda:9092
PAYMENT_INGEST_PORT=8081
SUBSCRIPTION_SERVICE_PORT=8082
API_GATEWAY_PORT=8080
EXPIRY_WORKER_PORT=8083
PUSH_PUBLISHER_PORT=8084
API_GATEWAY_TOKEN=change-me
APNS_KEY_ID=
APNS_TEAM_ID=
APNS_BUNDLE_ID=com.example.PrivateVPNAdmin
APNS_AUTH_KEY_PEM=
APNS_USE_SANDBOX=true
TEST_APNS_DEVICE_TOKEN=
```

## Releases

- Docker images publish to `ghcr.io/nehoko/private-vpn-project-<service>`
- macOS release packaging builds `PrivateVPNAdmin.app.zip`
- Release workflow triggers on tags like `v0.1.0`

## Status

- local functional test complete
- public GitHub repo available
- release workflow ready for Docker images and macOS app packaging
