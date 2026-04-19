# Private VPN Project - Implementation Plan

## Phase 1 - simplification

- remove backend services
- remove Telegram webhook assumptions
- move source of truth into macOS app

## Phase 2 - local CRUD

- create local subscriber model
- add persistence snapshot
- implement create, read, update, delete flows
- add filtering and search

## Phase 3 - reminders

- integrate Calendar app through `EventKit`
- create event `@username subscription expiration`
- attach `D-3` alert
- remove or update event on delete/edit/inactive

## Phase 4 - distribution

- build DMG installer
- update release workflow
- publish GitHub release
