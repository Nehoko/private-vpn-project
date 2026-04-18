# Private VPN Project - Current Status

## Current status

- process still manual
- no server-side payment ingest yet
- no subscriber system of record yet
- no native admin app yet
- no APNs push path yet

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
- server emits rare APNs-triggering events

## Risk

Main integration risk: official Telegram wallet support for exact personal-wallet incoming-payment callback flow still needs validation.
