import {
  Topics,
  type EventEnvelope,
  type PaymentReceivedEvent,
  type Subscriber,
  type SubscriptionRenewedEvent,
} from "@contracts/schema.ts";
import { createConsumer, createProducer, publishJson } from "@kafka/mod.ts";

const port = Number(Deno.env.get("SUBSCRIPTION_SERVICE_PORT") ?? "8082");
const consumer = await createConsumer("subscription-service", "subscription-service");
const producer = await createProducer("subscription-service");
const subscribers = new Map<number, Subscriber>();
const events: Array<EventEnvelope<unknown>> = [];

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function addDays(dateIso: string, days: number): string {
  const date = new Date(`${dateIso}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

async function startConsumer() {
  await consumer.subscribe({ topic: Topics.paymentsReceived, fromBeginning: false });

  await consumer.run({
    eachMessage: async ({ message }) => {
      if (!message.value) return;
      const envelope = JSON.parse(message.value.toString()) as EventEnvelope<PaymentReceivedEvent>;
      const payment = envelope.payload;
      const current = subscribers.get(payment.telegramId);
      if (!current) return;

      const renewed: SubscriptionRenewedEvent = {
        type: "subscription.renewed",
        eventId: crypto.randomUUID(),
        subscriberId: current.id,
        oldNextPayupDate: current.nextPayupDate,
        newNextPayupDate: addDays(current.nextPayupDate, 30),
        paymentId: payment.eventId,
      };

      const updated: Subscriber = {
        ...current,
        nextPayupDate: renewed.newNextPayupDate,
        active: true,
      };

      subscribers.set(payment.telegramId, updated);
      const nextEnvelope: EventEnvelope<SubscriptionRenewedEvent> = {
        key: updated.id,
        payload: renewed,
        emittedAt: new Date().toISOString(),
      };
      events.push(nextEnvelope);
      await publishJson(producer, Topics.subscriptionsEvents, updated.id, nextEnvelope);
    },
  });
}

void startConsumer();

Deno.serve({ port }, async (request) => {
  const url = new URL(request.url);

  if (request.method === "GET" && url.pathname === "/health") {
    return jsonResponse(200, {
      ok: true,
      service: "subscription-service",
      subscribers: subscribers.size,
    });
  }

  if (request.method === "GET" && url.pathname === "/subscribers") {
    return jsonResponse(200, { items: [...subscribers.values()] });
  }

  if (request.method === "POST" && url.pathname === "/subscribers") {
    const body = await request.json() as Subscriber;
    subscribers.set(body.telegramId, body);
    return jsonResponse(201, body);
  }

  if (request.method === "GET" && url.pathname === "/events") {
    return jsonResponse(200, { items: events });
  }

  return jsonResponse(404, { error: "not_found" });
});
