# mytodoapp

## What the App Does

mytodoapp is a simple Node.js + Express todo application that lets you add, update, complete, and delete tasks. It uses SQLite as its database, storing all todo items in a local `.db` file. The app is fully containerized using Docker with a multi-stage build, making it easy to run anywhere without any local Node.js setup.

---

## Architecture

```
┌─────────────────────────────────────────┐
│              Docker Container           │
│                                         │
│   ┌─────────┐       ┌───────────────┐   │
│   │ Express │──────▶│   SQLite DB   │   │
│   │  :3000  │       │  /tmp/todo.db │   │
│   └─────────┘       └───────┬───────┘   │
│                             │           │
└─────────────────────────────┼───────────┘
                              │
                    ┌─────────▼─────────┐
                    │   Named Volume    │
                    │    todo-data      │
                    │  (persists data)  │
                    └───────────────────┘

Host: localhost:3000 ──▶ Container: 3000
```

---

## Dockerfile Explained

```dockerfile
FROM node:18 AS builder
```
Uses the full Node.js 18 image as the build environment. Has all tools needed to compile native packages like `sqlite3`.

```dockerfile
WORKDIR /usr/src/app
```
Sets the working directory inside the container. All subsequent commands run from here.

```dockerfile
COPY package*.json ./
```
Copies `package.json` and `package-lock.json` before source code. Docker caches this layer — `npm ci` only re-runs when dependencies change.

```dockerfile
RUN npm ci
```
Installs all dependencies using `npm ci` — faster and more reliable than `npm install` as it uses the lockfile exactly.

```dockerfile
COPY . .
```
Copies the rest of the app source code. Placed after `npm ci` to preserve the dependency cache layer.

```dockerfile
FROM node:18-alpine
```
Switches to a lightweight Alpine-based image for the final container. No build tools, no compiler — just enough to run Node.js.

```dockerfile
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app .
```
Copies only the built output from Stage 1. Heavy build tools stay in Stage 1 and are discarded.

```dockerfile
EXPOSE 3000
```
Documents that the app listens on port 3000.

```dockerfile
CMD ["npm", "start"]
```
Default command that runs when the container starts.

---

## Image Size: Before vs After Multi-Stage Build

| Build Type | Base Image | Image Size |
|---|---|---|
| Single-stage | `node:21` | ~1GB |
| Multi-stage | `node:18` builder + `node:18-alpine` runtime | ~232MB |

**Reduction: ~77%** — build tools, compilers, and dev dependencies are left behind in the builder stage.

---

## How to Build and Run Locally

**1. Clone the repo**
```bash
git clone https://github.com/pradnyamandale28/Docker-Zero-to-Hero
cd learn_docker
```

**2. Build the image**
```bash
docker build -t mytodoapp .
```

**3. Run with a named volume (data persists across restarts)**
```bash
docker run -d \
  -p 3000:3000 \
  -v todo-data:/tmp \
  --name mytodoapp \
  mytodoapp
```

**4. Open the app**
```
http://localhost:3000
```

---

## Volume Mount Explained

```bash
-v todo-data:/tmp
```

| Part | Meaning |
|---|---|
| `todo-data` | Named volume managed by Docker |
| `/tmp` | Path inside container where `todo.db` is stored |

Without this flag, all todo data is lost when the container is removed. With the named volume, data survives container restarts and removals.

**Manage the volume:**
```bash
docker volume ls                  # list all volumes
docker volume inspect todo-data   # see where data is stored on host
docker volume rm todo-data        # delete volume and all data
```

---

## Docker Hub

```bash
# Pull the image
docker pull prad28/mytodoapp:1.0.0

# Run directly from Docker Hub
docker run -d -p 3000:3000 -v todo-data:/tmp prad28/mytodoapp:1.0.0
```

Image: `prad28/mytodoapp`
Tags: `1.0.0`, `latest`
