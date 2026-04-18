export type Uuid = string;

export interface Subscriber {
  id: Uuid;
  firstName: string;
  lastName?: string;
  telegramUsername: string;
  telegramId: number;
  startDate: string; // ISO YYYY-MM-DD
  nextPayupDate: string; // ISO YYYY-MM-DD
  active: boolean;
}

export interface PaymentReceivedEvent {
  type: "payment.received";
  eventId: Uuid;
  externalPaymentId: string;
  telegramId: number;
  telegramUsername?: string;
  amount: number;
  asset: string;
  paidAt: string;
  rawPayload: Record<string, unknown>;
}

export interface SubscriptionRenewedEvent {
  type: "subscription.renewed";
  eventId: Uuid;
  subscriberId: Uuid;
  oldNextPayupDate: string;
  newNextPayupDate: string;
  paymentId: Uuid;
}

export interface SubscriptionReminderEvent {
  type: "subscription.expiring_soon" | "subscription.due_today";
  eventId: Uuid;
  subscriberId: Uuid;
  nextPayupDate: string;
  reminderKind: "d_minus_3" | "due_today";
}

export interface DeviceRegistration {
  deviceId: string;
  platform: "macos";
  apnsToken: string;
  userLabel?: string;
}

export interface BootstrapResponse {
  generatedAt: string;
  subscribers: Subscriber[];
  expiringSoon: Subscriber[];
  cursor: string;
}

export interface EventEnvelope<TPayload> {
  key: string;
  payload: TPayload;
  emittedAt: string;
}

export type NotificationEvent = SubscriptionReminderEvent | SubscriptionRenewedEvent;

export const Topics = {
  paymentsReceived: "payments.received",
  subscriptionsEvents: "subscriptions.events",
  notificationsEvents: "notifications.events",
  devicesPush: "devices.push",
} as const;

export function ddmmyyyyToIso(input: string): string {
  const match = /^(\d{2})\.(\d{2})\.(\d{4})$/.exec(input);
  if (!match) {
    throw new Error(`Invalid date format: ${input}`);
  }

  const [, day, month, year] = match;
  return `${year}-${month}-${day}`;
}

export function isoToDdmmyyyy(input: string): string {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(input);
  if (!match) {
    throw new Error(`Invalid ISO date format: ${input}`);
  }

  const [, year, month, day] = match;
  return `${day}.${month}.${year}`;
}
