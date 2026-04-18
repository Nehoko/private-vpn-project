# Private VPN Project - Implementation Plan

## Phase 1 - wiki + source of truth

- create notebook and synthesized project pages
- keep global `index` and `log` updated
- validate Telegram wallet callback/support surface

## Phase 2 - infra + contracts

- create monorepo
- define shared API and Kafka contracts
- add Compose stack for `postgres` and `redpanda`
- add Dockerfile per server app

## Phase 3 - backend services

- build `payment-ingest`
- build `subscription-service`
- build `api-gateway`
- build `expiry-worker`
- build `push-publisher`

## Phase 4 - macOS app

- native SwiftUI shell
- bootstrap fetch on launch
- APNs device registration
- local state update after wake
- native notifications for due subscribers

## Phase 5 - production hardening

- replace in-memory scaffolding with real database persistence in services
- add APNs JWT signing
- add idempotency ledger for incoming payments
- add CI, secrets handling, and GitHub publication
