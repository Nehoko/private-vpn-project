FROM denoland/deno:2.2.7

WORKDIR /app
COPY deno.json deno.json
COPY packages packages
COPY apps/payment-ingest apps/payment-ingest

RUN deno cache apps/payment-ingest/main.ts

CMD ["run", "-A", "apps/payment-ingest/main.ts"]
