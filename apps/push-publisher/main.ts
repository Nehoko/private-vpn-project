import { createConsumer } from "@kafka/mod.ts";

const port = Number(Deno.env.get("PUSH_PUBLISHER_PORT") ?? "8084");
const consumer = await createConsumer("push-publisher", "push-publisher");

async function sendApnsPush(deviceToken: string, payload: unknown): Promise<void> {
  const useSandbox = (Deno.env.get("APNS_USE_SANDBOX") ?? "true") === "true";
  const base = useSandbox
    ? "https://api.sandbox.push.apple.com"
    : "https://api.push.apple.com";

  const response = await fetch(`${base}/3/device/${deviceToken}`, {
    method: "POST",
    headers: {
      "apns-topic": Deno.env.get("APNS_BUNDLE_ID") ?? "",
      "content-type": "application/json",
      authorization: `bearer ${Deno.env.get("APNS_AUTH_KEY_PEM") ?? ""}`,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    console.error("APNs push failed", response.status, await response.text());
  }
}

async function startConsumer() {
  await consumer.subscribe({ topic: "notifications.events", fromBeginning: false });
  await consumer.run({
    eachMessage: async ({ message }) => {
      if (!message.value) return;
      const payload = JSON.parse(message.value.toString());

      const token = Deno.env.get("TEST_APNS_DEVICE_TOKEN");
      if (!token) {
        console.warn("Skipping APNs send; TEST_APNS_DEVICE_TOKEN missing");
        return;
      }

      await sendApnsPush(token, {
        aps: {
          "content-available": 1,
        },
        event: payload,
      });
    },
  });
}

void startConsumer();

Deno.serve({ port }, (_request) => {
  return new Response(JSON.stringify({ ok: true, service: "push-publisher" }), {
    headers: { "content-type": "application/json" },
  });
});
