import { Topics, type EventEnvelope, type SubscriptionReminderEvent } from "@contracts/schema.ts";
import { createProducer, publishJson } from "@kafka/mod.ts";

const port = Number(Deno.env.get("EXPIRY_WORKER_PORT") ?? "8083");
const producer = await createProducer("expiry-worker");
const subscriptionServiceBase = Deno.env.get("SUBSCRIPTION_SERVICE_BASE_URL") ??
  "http://subscription-service:8082";

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function diffDays(dateIso: string): number {
  const now = new Date();
  now.setUTCHours(0, 0, 0, 0);
  const target = new Date(`${dateIso}T00:00:00Z`);
  return Math.round((target.getTime() - now.getTime()) / 86_400_000);
}

async function emitReminders(): Promise<number> {
  const response = await fetch(`${subscriptionServiceBase}/subscribers`);
  const payload = await response.json() as { items: Array<{ id: string; nextPayupDate: string; active: boolean }> };
  let count = 0;

  for (const subscriber of payload.items) {
    if (!subscriber.active) continue;
    const days = diffDays(subscriber.nextPayupDate);
    const reminderKind = days === 3 ? "d_minus_3" : days === 0 ? "due_today" : undefined;
    if (!reminderKind) continue;

    const event: SubscriptionReminderEvent = {
      type: reminderKind === "d_minus_3" ? "subscription.expiring_soon" : "subscription.due_today",
      eventId: crypto.randomUUID(),
      subscriberId: subscriber.id,
      nextPayupDate: subscriber.nextPayupDate,
      reminderKind,
    };
    const envelope: EventEnvelope<SubscriptionReminderEvent> = {
      key: subscriber.id,
      payload: event,
      emittedAt: new Date().toISOString(),
    };
    await publishJson(producer, Topics.notificationsEvents, subscriber.id, envelope);
    count += 1;
  }

  return count;
}

Deno.serve({ port }, async (request) => {
  const url = new URL(request.url);

  if (request.method === "GET" && url.pathname === "/health") {
    return jsonResponse(200, { ok: true, service: "expiry-worker" });
  }

  if (request.method === "POST" && url.pathname === "/run") {
    const emitted = await emitReminders();
    return jsonResponse(200, { emitted });
  }

  return jsonResponse(404, { error: "not_found" });
});
