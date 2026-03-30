FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /src/app

COPY package.json ./
RUN npm install

# =============================

FROM node:20-alpine AS builder
WORKDIR /src/app

COPY --from=deps /src/app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
ENV NEXT_PUBLIC_BASE_PATH=/capstone25/cp25ssa1   

RUN npm run build

# =============================

FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN apk add --no-cache curl

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# ✅ config
COPY --from=builder /src/app/next.config.* ./
COPY --from=builder /src/app/package.json ./

# ✅ public
COPY --from=builder /src/app/public ./public

# ✅ FIX ตรงนี้ 🔥
COPY --from=builder --chown=nextjs:nodejs /src/app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /src/app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]