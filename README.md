# Private VPN Project

Native macOS admin app for manual VPN subscription tracking.

Public repository: <https://github.com/Nehoko/private-vpn-project>

## Stack

- `admin-macos`: native `SwiftUI` app
- local JSON persistence in Application Support
- Apple Calendar integration through `EventKit`
- GitHub Actions release workflow for macOS installer

## Manual flow

1. Friend pays `5 USDT` in Telegram wallet manually.
2. Admin opens macOS app.
3. Admin creates or updates subscriber record manually.
4. App stores subscriber locally.
5. App creates or updates Calendar event:
   - title: `@username subscription expiration`
   - calendar: `Private VPN Admin`
   - alert: `D-3`

Telegram Wallet API is closed for newcomers. No backend, no webhook, no Kafka, no server sync in this version.

## Features

- full local CRUD for subscribers
- native sidebar/detail macOS UI
- clickable Telegram username and Telegram ID that open Telegram chat
- per-subscriber VPN configuration attachment
- active/inactive and expiring-soon filters
- relative last-update label:
  - `today at hh:mm:ss`
  - `yesterday at hh:mm:ss`
  - `n days ago at hh:mm:ss`
- Calendar event sync on create/edit/delete
- `Sync Calendar` action to rebuild reminders

## Subscriber fields

- `first_name`
- `last_name` optional
- `telegram_username`
- `telegram_id`
- `start_date`
- `next_payup_date`
- `active`

## Calendar integration

App requests Calendar permission on first reminder sync.

For active subscriber app creates event in app-managed `Private VPN Admin` calendar:

- title: `@username subscription expiration`
- event date: `next_payup_date`
- all-day: `true`
- alert: `3 days before`

If subscriber becomes inactive or deleted, app removes linked calendar event.

## Local run

```bash
cd apps/admin-macos
swift build
swift run PrivateVPNAdmin
```

## Persistence

App stores local data at:

```txt
~/Library/Application Support/PrivateVPNAdmin/subscribers.json
```

VPN configuration attachments stored under:

```txt
~/Library/Application Support/PrivateVPNAdmin/vpn-configs/
```

## Release packaging

Build installer locally:

```bash
./scripts/package_admin_macos.sh
```

Output:

```txt
dist/PrivateVPNAdmin.dmg
```

## Installer

GitHub release currently publishes unsigned drag-and-drop DMG installer.

Inside DMG:

- `PrivateVPNAdmin.app`
- symlink to `/Applications`

## macOS signing

If you download unsigned build on another Mac, Gatekeeper may block launch with errors like:

- `"PrivateVPNAdmin.app" can't be opened because Apple cannot check it for malicious software.`
- `"PrivateVPNAdmin.app" is damaged and can't be opened.`

### Quick local workaround for testing only

Use this only on a Mac you control. This is not proper distribution signing.

1. Copy app into `/Applications`.
2. Remove quarantine flag.
3. Add ad-hoc signature.

```bash
xattr -dr com.apple.quarantine /Applications/PrivateVPNAdmin.app
codesign --force --deep --sign - /Applications/PrivateVPNAdmin.app
```

### Proper fix for release builds

To ship app that opens normally on other Macs, sign app bundle with Developer ID certificate, then notarize DMG.

1. Join Apple Developer Program.
2. Create or download `Developer ID Application` certificate into Keychain Access.
3. Verify certificate name:

```bash
security find-identity -v -p codesigning
```

4. Export signer identity into env var:

```bash
export APP_SIGN_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)"
```

5. Build app:

```bash
./scripts/package_admin_macos.sh
```

6. Sign app bundle before creating final DMG:

```bash
codesign \
  --force \
  --deep \
  --options runtime \
  --sign "$APP_SIGN_IDENTITY" \
  dist/PrivateVPNAdmin.app
```

7. Rebuild DMG from signed app or create DMG after signing.
8. Notarize DMG:

```bash
xcrun notarytool submit dist/PrivateVPNAdmin.dmg \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "YOUR_APP_SPECIFIC_PASSWORD" \
  --wait
```

9. Staple notarization ticket:

```bash
xcrun stapler staple dist/PrivateVPNAdmin.dmg
```

10. Verify result:

```bash
spctl -a -vvv dist/PrivateVPNAdmin.app
spctl -a -vvv dist/PrivateVPNAdmin.dmg
codesign --verify --deep --strict --verbose=2 dist/PrivateVPNAdmin.app
```

Without Developer ID signing and notarization, GitHub release artifacts may work only after manual quarantine removal on each target Mac.

## Workflow

```mermaid
flowchart LR
    A["Friend pays 5 USDT manually in Telegram Wallet"] --> B["Admin opens PrivateVPNAdmin"]
    B --> C["Admin creates or edits subscriber record"]
    C --> D["App stores subscriber in local JSON file"]
    D --> E["App creates or updates Calendar event"]
    E --> F["Calendar shows @username subscription expiration with D-3 alert"]
```

## Repository shape

- `apps/admin-macos` Swift package for app
- `scripts/package_admin_macos.sh` local installer packaging
- `.github/workflows/release.yml` GitHub release workflow

## Releases

- GitHub releases publish `PrivateVPNAdmin.dmg`
- workflow triggers on tags like `v0.3.0`

## Status

- manual local-only architecture
- backend removed
- full CRUD in macOS app
- Calendar reminder integration implemented
- app-managed `Private VPN Admin` calendar implemented
- UI polished for release `v0.3.2`
- DMG installer release flow implemented
