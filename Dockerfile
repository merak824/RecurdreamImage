# syntax=docker/dockerfile:1.7

FROM node:22-bookworm-slim AS base
ENV NEXT_TELEMETRY_DISABLED=1
WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

FROM base AS frontend-build
COPY package.json ./package.json
COPY frontend/package.json frontend/package-lock.json ./frontend/
WORKDIR /app/frontend
RUN npm ci
COPY frontend/. ./
RUN npm run build

FROM base AS backend-deps
COPY backend/package.json backend/package-lock.json ./backend/
WORKDIR /app/backend
RUN npm ci --omit=dev

FROM node:22-bookworm-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    PORT=3000 \
    HOSTNAME=0.0.0.0 \
    NOVA_IMAGE_DIR=/app/backend/nova-images \
    NEXT_TELEMETRY_DISABLED=1

COPY --from=backend-deps /app/backend/node_modules ./backend/node_modules
COPY --from=frontend-build /app/frontend/out ./frontend/out
COPY backend/server.js ./backend/server.js
COPY backend/package.json ./backend/package.json
COPY backend/package-lock.json ./backend/package-lock.json
COPY backend/blacklist.json ./backend/blacklist.json
COPY backend/prompts.json ./backend/prompts.json
COPY backend/.env.example ./backend/.env.example

RUN mkdir -p /app/backend/nova-images

EXPOSE 3000
CMD ["node", "backend/server.js"]
