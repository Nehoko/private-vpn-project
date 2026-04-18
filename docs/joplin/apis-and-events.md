# Private VPN Project - APIs and Events

## REST endpoints

- `POST /auth/session`
- `GET /bootstrap`
- `GET /subscribers`
- `GET /subscribers/:id`
- `GET /events?since=<cursor>`
- `GET /health`
- `POST /webhooks/telegram-bot`
- `POST /webhooks/telegram-wallet`

## Kafka topics

- `payments.received`
- `subscriptions.events`
- `notifications.events`

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

## Telegram auth

- `/webhooks/telegram-bot`
  - header `X-Telegram-Bot-Api-Secret-Token`
  - body contains Telegram `successful_payment` update
- `/webhooks/telegram-wallet`
  - header `Authorization: Bearer <TELEGRAM_BRIDGE_BEARER_TOKEN>`
  - body contains normalized wallet bridge payload
