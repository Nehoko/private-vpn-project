FROM denoland/deno:2.2.7

WORKDIR /app
COPY deno.json deno.json
COPY packages packages
COPY apps/api-gateway apps/api-gateway

RUN deno cache apps/api-gateway/main.ts

CMD ["run", "-A", "apps/api-gateway/main.ts"]
