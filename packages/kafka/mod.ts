import { Kafka, logLevel, type Consumer, type Producer } from "npm:kafkajs";

const brokers = (Deno.env.get("KAFKA_BROKERS") ?? "localhost:9092").split(",");

function createKafka(clientId: string): Kafka {
  return new Kafka({
    clientId,
    brokers,
    logLevel: logLevel.ERROR,
  });
}

export async function createProducer(clientId: string): Promise<Producer> {
  const producer = createKafka(clientId).producer();
  await producer.connect();
  return producer;
}

export async function createConsumer(clientId: string, groupId: string): Promise<Consumer> {
  const consumer = createKafka(clientId).consumer({ groupId });
  await consumer.connect();
  return consumer;
}

export async function publishJson(
  producer: Producer,
  topic: string,
  key: string,
  payload: unknown,
): Promise<void> {
  await producer.send({
    topic,
    messages: [{ key, value: JSON.stringify(payload) }],
  });
}
