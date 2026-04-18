# Private VPN Project - Sources

## Official docs

- Telegram Bot Payments: <https://core.telegram.org/bots/payments>
- Telegram Bot API `setWebhook`: <https://core.telegram.org/bots/api#setwebhook>
- Wallet Pay portal: <https://pay.wallet.tg/>

## Source note

- Bot Payments documentation is official and clear for bot-driven merchant payments.
- Direct official callback docs for personal Telegram Wallet incoming `USDT` transfer were not confirmed during implementation.
- If official callback/webhook support is absent for personal-wallet receipts, use explicit bridge adapter or operator-confirmed intake path.
