  # Stage 1 — Builder
  # Uses full node:18 image which has all build tools (gcc, python, etc.)
  # needed to compile native dependencies like sqlite3
  FROM node:18 AS builder

  WORKDIR /usr/src/app

  # Copy package files first — Docker caches this layer
  # npm install only re-runs if package.json or package-lock.json changes
  COPY package*.json ./

  # Install ALL dependencies including devDeps needed for build
  RUN npm ci

  # Copy rest of source code after install (cache optimization)
  COPY . .


  # Stage 2 — Runtime
  # Lightweight alpine image — no build tools, no compiler, much smaller
  FROM node:18-alpine

  WORKDIR /usr/src/app

  # Copy only production node_modules from builder
  COPY --from=builder /usr/src/app/node_modules ./node_modules

  # Copy app source
  COPY --from=builder /usr/src/app .

  EXPOSE 3000

  CMD ["npm", "start"]