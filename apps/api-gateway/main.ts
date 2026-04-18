import {
  type BootstrapResponse,
  type EventEnvelope,
  type Subscriber,
} from "@contracts/schema.ts";

const port = Number(Deno.env.get("API_GATEWAY_PORT") ?? "8080");
const token = Deno.env.get("API_GATEWAY_TOKEN") ?? "change-me";
const subscriptionServiceBase = Deno.env.get("SUBSCRIPTION_SERVICE_BASE_URL") ??
  "http://subscription-service:8082";

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function isAuthorized(request: Request): boolean {
  const header = request.headers.get("authorization");
  return header === `Bearer ${token}`;
}

async function readSubscribers(): Promise<Subscriber[]> {
  const response = await fetch(`${subscriptionServiceBase}/subscribers`);
  const payload = await response.json() as { items: Subscriber[] };
  return payload.items;
}

async function readEvents(): Promise<Array<EventEnvelope<unknown>>> {
  const response = await fetch(`${subscriptionServiceBase}/events`);
  const payload = await response.json() as { items: Array<EventEnvelope<unknown>> };
  return payload.items;
}

function expiringSoon(subscribers: Subscriber[]): Subscriber[] {
  const now = new Date();
  now.setUTCHours(0, 0, 0, 0);

  return subscribers.filter((subscriber) => {
    if (!subscriber.active) return false;
    const due = new Date(`${subscriber.nextPayupDate}T00:00:00Z`);
    const days = Math.round((due.getTime() - now.getTime()) / 86_400_000);
    return days >= 0 && days <= 3;
  });
}

Deno.serve({ port }, async (request) => {
  const url = new URL(request.url);

  if (request.method === "GET" && url.pathname === "/health") {
    return jsonResponse(200, { ok: true, service: "api-gateway" });
  }

  if (request.method === "POST" && url.pathname === "/auth/session") {
    return jsonResponse(200, { token, tokenType: "Bearer" });
  }

  if (!isAuthorized(request)) {
    return jsonResponse(401, { error: "unauthorized" });
  }

  if (request.method === "GET" && url.pathname === "/bootstrap") {
    const subscribers = await readSubscribers();
    const response: BootstrapResponse = {
      generatedAt: new Date().toISOString(),
      subscribers,
      expiringSoon: expiringSoon(subscribers),
      cursor: new Date().toISOString(),
    };
    return jsonResponse(200, response);
  }

  if (request.method === "GET" && url.pathname === "/subscribers") {
    return jsonResponse(200, { items: await readSubscribers() });
  }

  if (request.method === "GET" && url.pathname.startsWith("/subscribers/")) {
    const subscriberId = url.pathname.split("/").at(-1);
    const subscribers = await readSubscribers();
    const subscriber = subscribers.find((item) => item.id === subscriberId);
    return subscriber ? jsonResponse(200, subscriber) : jsonResponse(404, { error: "not_found" });
  }

  if (request.method === "GET" && url.pathname === "/events") {
    const events = await readEvents();
    return jsonResponse(200, {
      items: events,
      since: url.searchParams.get("since"),
    });
  }

  return jsonResponse(404, { error: "not_found" });
});
