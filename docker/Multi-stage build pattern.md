# Multi-stage Build Pattern

A **multi-stage build** uses multiple `FROM` instructions in a single `Dockerfile`. Each `FROM` starts a new stage with its own filesystem. You can selectively **copy artifacts** from one stage into another, leaving behind everything you don't need in the final image.

## Why It Matters

Without multi-stage builds, a typical workflow forces a choice:
- **Fat image**: include the compiler/SDK → image ships with build tools (large, insecure surface)
- **Two Dockerfiles**: one to build, one to package → complex CI pipelines, easy to get out of sync

Multi-stage builds solve both problems in a single file.

## Structure

```dockerfile
# Stage 1 – Builder
FROM golang:1.22 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp .

# Stage 2 – Final image
FROM alpine:3.19
WORKDIR /app
COPY --from=builder /app/myapp .
CMD ["./myapp"]
```

Key syntax:
- `AS <name>` — names a stage so you can reference it later
- `COPY --from=<name>` — copies files from a previous stage instead of the host

## Why It Is Useful

| Problem | Without multi-stage | With multi-stage |
|---|---|---|
| Image size | Compiler + SDK shipped to prod | Only the compiled binary shipped |
| Security | Large attack surface (gcc, npm, etc.) | Minimal OS + app only |
| Secrets in layers | Build credentials visible in history | Credentials stay in builder stage, never copied |
| Pipeline complexity | Two separate Dockerfiles to maintain | One file, self-contained |
| Cache efficiency | Full rebuild on any change | Each stage cached independently |

## Common Patterns

### 1. Build → Run (compiled languages)
```dockerfile
FROM node:20 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build          # produces /app/dist

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

### 2. Test → Build → Run
```dockerfile
FROM python:3.12 AS test
COPY requirements*.txt ./
RUN pip install -r requirements-dev.txt
COPY . .
RUN pytest

FROM python:3.12-slim AS final
COPY requirements.txt ./
RUN pip install -r requirements.txt
COPY src/ ./src/
CMD ["python", "src/main.py"]
```

### 3. Named stage reuse (monorepo)
```dockerfile
FROM node:20 AS deps
RUN npm ci

FROM deps AS build-api
RUN npm run build:api

FROM deps AS build-web
RUN npm run build:web
```

## Targeting a Specific Stage

```bash
# Build only up to the 'test' stage (useful in CI)
docker build --target test -t myapp:test .
```

This lets CI run tests without producing a final image, and only proceed to the `final` stage if tests pass.

## Size Comparison Example (Go app)

| Approach | Base image | Final size |
|---|---|---|
| Single stage | `golang:1.22` | ~900 MB |
| Multi-stage | `alpine:3.19` | ~10 MB |

The final image contains **only what is needed at runtime** — no compiler, no source code, no intermediate files.
