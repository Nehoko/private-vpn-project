create table if not exists subscribers (
  id uuid primary key,
  first_name text not null,
  last_name text,
  telegram_username text not null,
  telegram_id bigint not null unique,
  start_date date not null,
  next_payup_date date not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists payments (
  id uuid primary key,
  external_payment_id text not null unique,
  telegram_id bigint not null,
  telegram_username text,
  amount numeric(12, 2) not null,
  asset text not null,
  paid_at timestamptz not null,
  raw_payload jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists device_registrations (
  id uuid primary key,
  device_id text not null unique,
  platform text not null,
  apns_token text not null,
  user_label text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists notification_ledger (
  id uuid primary key,
  subscriber_id uuid not null references subscribers(id) on delete cascade,
  reminder_kind text not null,
  reminder_for_date date not null,
  emitted_at timestamptz not null default now(),
  unique (subscriber_id, reminder_kind, reminder_for_date)
);
