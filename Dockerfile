FROM node:18-alpine

RUN apk update && apk upgrade --no-cache

WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/static ./static
COPY --from=builder /app/package.json ./

EXPOSE 3000
CMD ["node", "src/index.js"]