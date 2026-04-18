# Private VPN Project - Architecture

## Repo

Monorepo.

- `apps/payment-ingest`
- `apps/subscription-service`
- `apps/api-gateway`
- `apps/expiry-worker`
- `apps/admin-macos`
- `packages/contracts`
- `packages/kafka`
- `infra/compose`

## Infra

- `Postgres` as source of truth
- `Redpanda` as Kafka-compatible broker
- Docker Compose for local/dev stack

## Runtime flow

1. Telegram bot payments webhook or wallet bridge adapter sends payload to `payment-ingest`.
2. `payment-ingest` emits Kafka `payments.received`.
3. `subscription-service` updates subscriber state and emits `subscriptions.events`.
4. `expiry-worker` emits due-date notification events once per day.
5. `api-gateway` exposes REST snapshot to admin client.
6. `admin-macos` polls on launch, manual refresh, and every 6 hours, updates UI, shows native notification.

## Client design

- native SwiftUI first
- no persistent socket
- no Kafka client in app
- no persistent open connection
- 6-hour polling cadence for low background activity
