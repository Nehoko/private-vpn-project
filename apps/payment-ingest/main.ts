import { Topics, type EventEnvelope, type PaymentReceivedEvent } from "@contracts/schema.ts";
import { createProducer, publishJson } from "@kafka/mod.ts";

const port = Number(Deno.env.get("PAYMENT_INGEST_PORT") ?? "8081");
const producer = await createProducer("payment-ingest");

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function randomId(): string {
  return crypto.randomUUID();
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

Deno.serve({ port }, async (request) => {
  const url = new URL(request.url);

  if (request.method === "GET" && url.pathname === "/health") {
    return jsonResponse(200, { ok: true, service: "payment-ingest" });
  }

  if (request.method === "POST" && url.pathname === "/webhooks/telegram-wallet") {
    const payload = await request.json() as Record<string, unknown>;
    const event = parsePaymentEvent(payload);
    const envelope: EventEnvelope<PaymentReceivedEvent> = {
      key: String(event.telegramId),
      payload: event,
      emittedAt: new Date().toISOString(),
    };

    await publishJson(producer, Topics.paymentsReceived, envelope.key, envelope);
    return jsonResponse(202, { accepted: true, eventId: event.eventId });
  }

  return jsonResponse(404, { error: "not_found" });
});
