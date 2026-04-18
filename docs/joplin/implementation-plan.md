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
- add Telegram bot webhook auth
- add wallet bridge auth

## Phase 4 - macOS app

- native SwiftUI shell
- bootstrap fetch on launch
- local state update after scheduled refresh
- 6-hour polling loop
- native notifications for due subscribers

## Phase 5 - production hardening

- replace in-memory scaffolding with real database persistence in services
- add idempotency ledger for incoming payments
- validate personal-wallet callback support or keep bridge adapter
- add CI, secrets handling, and GitHub publication
