# Private VPN Project

Monorepo scaffold for subscription tracking around private VPN access.

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

## Status

This commit scaffolds local code, compose, docs, and app structure.

GitHub publication is not done here because no repository remote was provided or created in-session.
