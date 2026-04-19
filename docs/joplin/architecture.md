# Private VPN Project - Architecture

## Repo

Monorepo, macOS app only.

- `apps/admin-macos`
- `scripts/package_admin_macos.sh`
- `.github/workflows/release.yml`
- `docs/joplin`

## Runtime flow

1. Friend pays manually in Telegram Wallet.
2. Admin opens `PrivateVPNAdmin`.
3. Admin creates or edits subscriber record manually.
4. App stores subscriber in local JSON snapshot.
5. App creates or updates Calendar event for expiration date.
6. Calendar alert fires `D-3`.

## Client design

- native SwiftUI split view
- local persistence
- no backend
- no network dependency
- Calendar integration through `EventKit`
