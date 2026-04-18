# Private VPN Project

Monorepo scaffold for subscription tracking around private VPN access.

Public repository: <https://github.com/Nehoko/private-vpn-project>

## Stack

- `payment-ingest`: Deno/TypeScript webhook intake for Telegram wallet or bridge adapter
- `subscription-service`: Deno/TypeScript subscriber state + renewal logic
- `api-gateway`: Deno/TypeScript admin bootstrap + delta API
- `expiry-worker`: Deno/TypeScript daily due-date scan
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
```

4. Run macOS admin app.

```bash
cd apps/admin-macos
swift run PrivateVPNAdmin
```

App now shows first-launch popup for backend URL and admin token, so shell env vars are optional. App refreshes on launch, manual refresh, and every 6 hours while open.

## Telegram connection

Project supports 2 Telegram payment intake paths:

1. official Telegram Bot Payments webhook
2. authenticated wallet bridge webhook for personal-wallet/manual adapter flows

### Required Telegram env vars

```env
TELEGRAM_BRIDGE_BEARER_TOKEN=change-me-telegram-bridge
TELEGRAM_BOT_WEBHOOK_SECRET=change-me-telegram-bot-secret
```

### Official Telegram Bot Payments

Official docs:

- [Telegram Bot Payments](https://core.telegram.org/bots/payments)
- [Telegram Bot API setWebhook](https://core.telegram.org/bots/api#setwebhook)

Use this when payment comes through Telegram bot invoice flow and Telegram sends `successful_payment` updates to your server.

1. Create bot in `@BotFather`.
2. Connect payments provider in `Bot Settings -> Payments`.
3. Set webhook to payment-ingest:

```bash
export TELEGRAM_BOT_TOKEN=123456:ABCDEF
export PUBLIC_PAYMENT_INGEST_URL=https://vpn.example.com
export TELEGRAM_BOT_WEBHOOK_SECRET=change-me-telegram-bot-secret

curl -sS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
  -d "url=${PUBLIC_PAYMENT_INGEST_URL}/webhooks/telegram-bot" \
  -d "secret_token=${TELEGRAM_BOT_WEBHOOK_SECRET}"
```

4. Telegram sends payment updates to `POST /webhooks/telegram-bot`.
5. `payment-ingest` verifies header `X-Telegram-Bot-Api-Secret-Token`.
6. Service parses `message.successful_payment` and emits `payments.received`.

### Wallet bridge mode

Stable official docs for direct callback on personal Telegram Wallet incoming USDT transfers were not confirmed during this implementation. Repo therefore supports bridge mode: small adapter receives wallet event, normalizes payload, sends it into `payment-ingest`.

Endpoint:

```txt
POST /webhooks/telegram-wallet
Authorization: Bearer $TELEGRAM_BRIDGE_BEARER_TOKEN
```

Payload example:

```json
{
  "telegram_id": 123456789,
  "telegram_username": "friend_name",
  "amount": 5,
  "asset": "USDT",
  "external_payment_id": "wallet-transfer-001",
  "paid_at": "2026-04-18T08:15:00Z"
}
```

Quick local test:

```bash
curl -sS -X POST http://127.0.0.1:8081/webhooks/telegram-wallet \
  -H "Authorization: Bearer change-me-telegram-bridge" \
  -H "Content-Type: application/json" \
  -d '{
    "telegram_id": 123456789,
    "telegram_username": "friend_name",
    "amount": 5,
    "asset": "USDT",
    "external_payment_id": "wallet-transfer-001",
    "paid_at": "2026-04-18T08:15:00Z"
  }'
```

## Workflow

```mermaid
flowchart LR
    A["Friend pays 5 USDT in Telegram flow"] --> B["Telegram bot webhook or wallet bridge webhook"]
    B --> C["payment-ingest validates secret/token"]
    C --> D["Kafka topic payments.received"]
    D --> E["subscription-service renews subscriber and updates payup date"]
    E --> F["api-gateway exposes latest state via /bootstrap"]
    F --> G["admin-macos polls on launch, manual refresh, or every 6 hours"]
    G --> H["admin-macos UI shows updated subscriber state"]
```

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
API_GATEWAY_TOKEN=change-me
TELEGRAM_BRIDGE_BEARER_TOKEN=change-me-telegram-bridge
TELEGRAM_BOT_WEBHOOK_SECRET=change-me-telegram-bot-secret
```

## Releases

- Docker images publish to `ghcr.io/nehoko/private-vpn-project-<service>`
- macOS release packaging builds `PrivateVPNAdmin.app.zip`
- Release workflow triggers on tags like `v0.1.0`

## Status

- local functional test complete
- public GitHub repo available
- release workflow ready for Docker images and macOS app packaging
- Telegram bot webhook path implemented
- 6-hour admin polling replaces APNs wake flow
