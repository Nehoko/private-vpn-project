# Private VPN Project - Sources

## Official docs

- Telegram Wallet Pay docs: <https://docs.wallet.tg/pay/>
- Wallet Pay portal: <https://pay.wallet.tg/>
- Telegram Bot Payments: <https://core.telegram.org/bots/payments>

## Source note

- Bot Payments documentation is official and clear for bot-driven merchant payments.
- Wallet Pay documentation exists and appears merchant-oriented.
- Exact fit for "friend sends `5 USDT` to my personal Telegram wallet and server gets callback" still needs implementation-time validation.
- If official callback/webhook support is absent for personal-wallet receipts, use explicit bridge adapter or operator-confirmed intake path.
