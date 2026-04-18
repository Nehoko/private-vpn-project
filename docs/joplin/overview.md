# Private VPN Project - Overview

## Summary

Desktop admin tool for private VPN subscriptions.

Goal:
- operator sees all subscribers
- operator gets low-power native macOS notifications
- renewals flow from server-side payment events, not manual spreadsheet edits

## Current operating model

1. User pays `5 USDT` to Telegram wallet.
2. Operator issues VPN credentials.
3. User starts using VPN.

## Target operating model

1. Payment source triggers server-side intake.
2. Intake emits Kafka `payment.received`.
3. Subscription service updates subscriber state.
4. Push publisher sends APNs wake event to admin macOS app.
5. Admin macOS app fetches fresh state via REST and shows native notification when needed.

## Constraints

- notebook path: `LLM Wiki/Wiki/Private VPN Project`
- synthesized project pages live in this notebook
- `index`, `log`, `Raw Sources`, `Ops` remain global
- backend services use async `Deno` + `TypeScript`
- each server app runs as Docker image in Compose
- macOS app uses native `SwiftUI`
