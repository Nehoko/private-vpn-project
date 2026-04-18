FROM denoland/deno:2.2.7

WORKDIR /app
COPY deno.json deno.json
COPY packages packages
COPY apps/push-publisher apps/push-publisher

RUN deno cache apps/push-publisher/main.ts

CMD ["run", "-A", "apps/push-publisher/main.ts"]
