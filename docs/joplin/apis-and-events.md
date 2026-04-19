# Private VPN Project - APIs and Events

## Runtime APIs

- local JSON persistence
- Apple Calendar integration via `EventKit`

## Persistence shape

### Subscriber

- `id`
- `firstName`
- `lastName`
- `telegramUsername`
- `telegramId`
- `startDate`
- `nextPayupDate`
- `active`
- `calendarEventIdentifier`

### Snapshot

- `updatedAt`
- `subscribers`

## Calendar reminder policy

- title: `@username subscription expiration`
- date: `nextPayupDate`
- alert: `D-3`
- inactive or deleted subscriber removes linked event
