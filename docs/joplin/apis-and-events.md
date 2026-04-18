# Private VPN Project - APIs and Events

## REST endpoints

- `POST /auth/session`
- `POST /devices/register`
- `GET /bootstrap`
- `GET /subscribers`
- `GET /subscribers/:id`
- `GET /events?since=<cursor>`
- `GET /health`

## Kafka topics

- `payments.received`
- `subscriptions.events`
- `notifications.events`
- `devices.push`

## Core events

### `payment.received`

- `externalPaymentId`
- `telegramId`
- `telegramUsername`
- `amount`
- `asset`
- `paidAt`

### `subscription.renewed`

- `subscriberId`
- `oldNextPayupDate`
- `newNextPayupDate`
- `paymentId`

### `subscription.expiring_soon`

- `subscriberId`
- `nextPayupDate`
- `reminderKind=d_minus_3`

### `subscription.due_today`

- `subscriberId`
- `nextPayupDate`
- `reminderKind=due_today`

## Notification policy

- emit `D-3` once
- emit `D` once
- suppress duplicates with server-side ledger
