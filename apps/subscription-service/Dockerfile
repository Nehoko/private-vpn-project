FROM denoland/deno:2.2.7

WORKDIR /app
COPY deno.json deno.json
COPY packages packages
COPY apps/subscription-service apps/subscription-service

RUN deno cache apps/subscription-service/main.ts

CMD ["run", "-A", "apps/subscription-service/main.ts"]
