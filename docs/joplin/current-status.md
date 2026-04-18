# Private VPN Project - Current Status

## Current status

- local stack works end-to-end with payment ingest, subscription renewal, admin bootstrap
- Telegram bot webhook path implemented
- wallet bridge webhook path implemented
- native macOS admin app exists and polls every 6 hours while open

## Required subscriber fields

- `first_name`
- `last_name` optional
- `telegram_username` required
- `telegram_id` required
- `start_date` required, input/output `dd.mm.yyyy`
- `next_payup_date` required, input/output `dd.mm.yyyy`
- `active` required boolean

## Current technical assumptions

- backend stores dates as ISO `YYYY-MM-DD`
- `telegram_id` is primary match key
- `telegram_username` is fallback for manual reconciliation only
- client keeps no open connection
- client polls on launch, manual refresh, and every 6 hours
- Telegram input paths:
  - official bot payments webhook: `/webhooks/telegram-bot`
  - wallet/manual bridge webhook: `/webhooks/telegram-wallet`

## Risk

Main integration risk: official Telegram support for exact personal-wallet incoming-wallet callback flow still not confirmed, so wallet bridge remains fallback path.
