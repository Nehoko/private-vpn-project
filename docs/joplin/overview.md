# Private VPN Project - Overview

## Summary

Desktop admin tool for manual VPN subscription tracking.

Goal:

- admin stores subscriber list locally
- admin edits subscriptions manually after Telegram wallet payment
- app creates Calendar reminders for upcoming expiration

## Current operating model

1. User pays `5 USDT` to Telegram wallet manually.
2. Admin issues VPN credentials.
3. Admin updates subscriber record in macOS app.

## Target operating model

1. Admin creates or edits subscriber locally.
2. App stores subscriber snapshot.
3. App syncs Calendar reminder.
4. Calendar alerts admin `D-3`.

## Constraints

- notebook path: `LLM Wiki/Wiki/Private VPN Project`
- synthesized project pages live in this notebook
- no server side
- no Telegram API integration
- macOS app uses native `SwiftUI`
