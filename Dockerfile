# Stage 1: install dependencies fresh from lock file
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Stage 2: final lean image
FROM node:18-alpine
RUN apk update && apk upgrade --no-cache
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY src ./src
COPY package.json ./

EXPOSE 3000
CMD ["node", "src/index.js"]