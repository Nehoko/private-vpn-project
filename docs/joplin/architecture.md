# Private VPN Project - Architecture

## Repo

Monorepo.

- `apps/payment-ingest`
- `apps/subscription-service`
- `apps/api-gateway`
- `apps/expiry-worker`
- `apps/push-publisher`
- `apps/admin-macos`
- `packages/contracts`
- `packages/kafka`
- `infra/compose`

## Infra

- `Postgres` as source of truth
- `Redpanda` as Kafka-compatible broker
- Docker Compose for local/dev stack

## Runtime flow

1. Telegram wallet webhook or bridge adapter sends payload to `payment-ingest`.
2. `payment-ingest` emits Kafka `payments.received`.
3. `subscription-service` updates subscriber state and emits `subscriptions.events`.
4. `expiry-worker` emits due-date notification events once per day.
5. `push-publisher` sends APNs pushes to registered macOS devices.
6. `admin-macos` wakes, fetches REST snapshot or deltas, updates UI, shows native notification.

## Client design

- native SwiftUI first
- no persistent socket
- no Kafka client in app
- no client cron
- low-power background behavior via APNs
