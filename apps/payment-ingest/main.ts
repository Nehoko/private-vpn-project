import { Topics, type EventEnvelope, type PaymentReceivedEvent } from "@contracts/schema.ts";
import { createProducer, publishJson } from "@kafka/mod.ts";

const port = Number(Deno.env.get("PAYMENT_INGEST_PORT") ?? "8081");
const producer = await createProducer("payment-ingest");
const bridgeBearerToken = Deno.env.get("TELEGRAM_BRIDGE_BEARER_TOKEN") ?? "change-me-telegram-bridge";
const telegramBotWebhookSecret = Deno.env.get("TELEGRAM_BOT_WEBHOOK_SECRET") ??
  "change-me-telegram-bot-secret";

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function randomId(): string {
  return crypto.randomUUID();
}

function unauthorized(message = "unauthorized"): Response {
  return jsonResponse(401, { error: message });
}

function extractBearerToken(request: Request): string | undefined {
  const header = request.headers.get("authorization");
  if (!header?.startsWith("Bearer ")) {
    return undefined;
  }
  return header.slice("Bearer ".length).trim();
}

function parsePaymentEvent(payload: Record<string, unknown>): PaymentReceivedEvent {
  const telegramId = Number(payload.telegram_id);
  if (!Number.isFinite(telegramId)) {
    throw new Error("telegram_id missing");
  }

  const amount = Number(payload.amount ?? 5);
  if (!Number.isFinite(amount)) {
    throw new Error("amount missing");
  }

  return {
    type: "payment.received",
    eventId: randomId(),
    externalPaymentId: String(payload.external_payment_id ?? randomId()),
    telegramId,
    telegramUsername: payload.telegram_username ? String(payload.telegram_username) : undefined,
    amount,
    asset: String(payload.asset ?? "USDT"),
    paidAt: new Date(String(payload.paid_at ?? new Date().toISOString())).toISOString(),
    rawPayload: payload,
  };
}

function parseTelegramBotUpdate(payload: Record<string, unknown>): PaymentReceivedEvent {
  const message = payload.message as Record<string, unknown> | undefined;
  const from = message?.from as Record<string, unknown> | undefined;
  const successfulPayment = message?.successful_payment as Record<string, unknown> | undefined;

  if (!from || !successfulPayment) {
    throw new Error("successful_payment update missing");
  }

  const telegramId = Number(from.id);
  if (!Number.isFinite(telegramId)) {
    throw new Error("telegram user missing");
  }

  const currency = String(successfulPayment.currency ?? "USD");
  const totalAmountMinor = Number(successfulPayment.total_amount);
  if (!Number.isFinite(totalAmountMinor)) {
    throw new Error("total_amount missing");
  }

  const divisor = currency === "XTR" ? 1 : 100;
  const paidAtUnix = Number(message?.date ?? Math.floor(Date.now() / 1_000));

  return {
    type: "payment.received",
    eventId: randomId(),
    externalPaymentId: String(
      successfulPayment.telegram_payment_charge_id ??
        successfulPayment.provider_payment_charge_id ??
        randomId(),
    ),
    telegramId,
    telegramUsername: from.username ? String(from.username) : undefined,
    amount: totalAmountMinor / divisor,
    asset: currency,
    paidAt: new Date(paidAtUnix * 1_000).toISOString(),
    rawPayload: payload,
  };
}

async function publishPayment(event: PaymentReceivedEvent): Promise<Response> {
  const envelope: EventEnvelope<PaymentReceivedEvent> = {
    key: String(event.telegramId),
    payload: event,
    emittedAt: new Date().toISOString(),
  };

  await publishJson(producer, Topics.paymentsReceived, envelope.key, envelope);
  return jsonResponse(202, { accepted: true, eventId: event.eventId });
}

Deno.serve({ port }, async (request) => {
  const url = new URL(request.url);

  if (request.method === "GET" && url.pathname === "/health") {
    return jsonResponse(200, {
      ok: true,
      service: "payment-ingest",
      telegramBotWebhookPath: "/webhooks/telegram-bot",
      telegramBridgePath: "/webhooks/telegram-wallet",
    });
  }

  if (request.method === "POST" && url.pathname === "/webhooks/telegram-wallet") {
    const token = extractBearerToken(request);
    if (token !== bridgeBearerToken) {
      return unauthorized("bridge token invalid");
    }

    const payload = await request.json() as Record<string, unknown>;
    const event = parsePaymentEvent(payload);
    return await publishPayment(event);
  }

  if (request.method === "POST" && url.pathname === "/webhooks/telegram-bot") {
    const secret = request.headers.get("x-telegram-bot-api-secret-token");
    if (secret !== telegramBotWebhookSecret) {
      return unauthorized("telegram secret invalid");
    }

    const payload = await request.json() as Record<string, unknown>;
    const event = parseTelegramBotUpdate(payload);
    return await publishPayment(event);
  }

  return jsonResponse(404, { error: "not_found" });
});
