# Private VPN Project - Current Status

## Current status

- Telegram wallet automation dropped because wallet API is closed for newcomers
- backend removed
- project is now local-only native macOS app
- subscriber records stored in local JSON file
- full CRUD implemented in app
- Calendar reminder sync implemented with `D-3` alert
- release packaging now builds macOS DMG installer

## Required subscriber fields

- `first_name`
- `last_name` optional
- `telegram_username`
- `telegram_id`
- `start_date`
- `next_payup_date`
- `active`

## Current technical assumptions

- app is source of truth
- persistence path: `~/Library/Application Support/PrivateVPNAdmin/subscribers.json`
- Calendar app is reminder system
- each active subscriber maps to one Calendar event
- event title format: `@username subscription expiration`

## Risk

- Calendar permission may be denied by user
- installer is unsigned DMG, not notarized
