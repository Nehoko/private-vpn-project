FROM denoland/deno:2.2.7

WORKDIR /app
COPY deno.json deno.json
COPY packages packages
COPY apps/expiry-worker apps/expiry-worker

RUN deno cache apps/expiry-worker/main.ts

CMD ["run", "-A", "apps/expiry-worker/main.ts"]
