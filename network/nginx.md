# NGINX

## What is NGINX?

NGINX (pronounced "engine-x") is a **high-performance web server** that also acts as a **reverse proxy**, **load balancer**, and **API gateway**.

It sits in front of your application and handles incoming HTTP traffic before it ever reaches your code.

```
Without NGINX:

  Client ──────────────────────────► Your App (port 3000)


With NGINX:

  Client ──────► NGINX ────────────► Your App (port 3000)
                 (port 80/443)
```

That middle position is where all its power comes from.

---

## What Problem Does NGINX Solve?

Your application server (Node, Python, Go, etc.) is good at running business logic. It is **not** designed to:

- Handle thousands of concurrent connections efficiently
- Terminate SSL/TLS
- Serve static files at high speed
- Route traffic to multiple services
- Rate-limit abusive clients

NGINX is purpose-built for all of that.

```
┌────────────────────────────────────────────────────────────┐
│                         NGINX                              │
│                                                            │
│  ✓ SSL termination      ✓ Static file serving             │
│  ✓ Load balancing       ✓ Rate limiting                   │
│  ✓ Reverse proxying     ✓ Caching                         │
│  ✓ Request routing      ✓ Compression (gzip)              │
└────────────────────────────────────────────────────────────┘
```

---

## Reverse Proxy — The Core Concept

==A **reverse proxy** receives requests on behalf of backend servers. The client never talks to your app directly.==

```
                        ┌─────────────────────┐
                        │       NGINX         │
                        │   (reverse proxy)   │
                        └──────────┬──────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          │                        │                        │
          ▼                        ▼                        ▼
   ┌─────────────┐         ┌─────────────┐         ┌─────────────┐
   │  App Server │         │  App Server │         │  App Server        │
   │  :3000      │         │  :3001      │         │  :3002         │
   └─────────────┘         └─────────────┘         └─────────────┘

Client sees: api.myapp.com
Client never sees: which server actually handled the request
```

**Why "reverse"?** A regular (forward) proxy sits in front of clients and speaks on their behalf. A reverse proxy sits in front of servers and speaks on their behalf. Opposite direction.

`location` is the matching mechanism inside NGINX. It pairs the incoming URL path to the right backend endpoint. This is also why NGINX is powerful as an API gateway — your individual services don't need to know about each other. NGINX owns routing entirely.

```
           NGINX knows everything
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
    User App    Order App   Payment App

    Each app only knows about itself.
```

---

## Load Balancing

When you have multiple instances of your app, NGINX distributes requests across them:

```
Incoming requests:   1  2  3  4  5  6
                     │  │  │  │  │  │
                     ▼  ▼  ▼  ▼  ▼  ▼
                  ┌─────────────────┐
                  │  NGINX          │
                  │  load balancer  │
                  └──────┬──────────┘
                         │
            ┌────────────┼────────────┐
            ▼            ▼            ▼
         Server A     Server B     Server C
         gets: 1,4    gets: 2,5    gets: 3,6
```

Strategies:
- **Round robin** — rotate evenly (default)
- **Least connections** — send to whichever server has fewest active requests
- **IP hash** — same client always hits same server (useful for sessions)

---

## SSL Termination

NGINX handles the HTTPS encryption/decryption so your app doesn't have to:

```
Client                    NGINX                    App Server
──────                    ─────                    ──────────
  │                         │                          │
  │──── HTTPS (encrypted) ──►│                          │
  │                         │──── HTTP (plain) ────────►│
  │                         │◄─── HTTP (plain) ─────────│
  │◄─── HTTPS (encrypted) ──│                          │
```

Your app only ever sees plain HTTP on localhost. Certificates live in NGINX, not scattered across every service.

---

## What is an API Gateway?

An **API Gateway** is a specialized reverse proxy that sits at the **entry point** of a system with multiple backend services (microservices). It is the single front door for all client requests.

```
                      ┌──────────────────────────┐
  Mobile App ────────►│                          │
  Web Browser ───────►│      API GATEWAY         │
  Third-party ───────►│                          │
                      └────────────┬─────────────┘
                                   │
               ┌───────────────────┼───────────────────┐
               │                   │                   │
               ▼                   ▼                   ▼
        ┌────────────┐      ┌────────────┐      ┌────────────┐
        │   User     │      │   Order    │      │  Payment   │
        │  Service   │      │  Service   │      │  Service   │
        └────────────┘      └────────────┘      └────────────┘
```

Without an API gateway, every client would need to know the address of every service. With it, clients talk to one place.

---

## API Gateway Responsibilities

```
┌──────────────────────────────────────────────────────────────┐
│                       API Gateway                            │
│                                                              │
│  ROUTING          /users/*   ──► User Service               │
│                   /orders/*  ──► Order Service              │
│                   /pay/*     ──► Payment Service            │
│                                                              │
│  AUTHENTICATION   verify JWT token before forwarding        │
│                                                              │
│  RATE LIMITING    100 requests/min per client IP            │
│                                                              │
│  LOGGING          log every request centrally               │
│                                                              │
│  TRANSFORMATION   reshape request/response if needed        │
│                                                              │
│  CACHING          return cached responses for hot routes    │
└──────────────────────────────────────────────────────────────┘
```

The big win: **cross-cutting concerns live in one place**, not duplicated in every service.

---

## NGINX as an API Gateway

NGINX can be configured to act as an API gateway. Here's what that config looks like conceptually:

```nginx
server {
    listen 443 ssl;
    server_name api.myapp.com;

    # Route /users to User Service
    location /users/ {
        proxy_pass http://user-service:3001;
    }

    # Route /orders to Order Service
    location /orders/ {
        proxy_pass http://order-service:3002;
    }

    # Rate limit this endpoint
    location /auth/ {
        limit_req zone=auth_limit burst=5;
        proxy_pass http://auth-service:3003;
    }
}
```

Each `location` block is a routing rule. NGINX matches the URL path and forwards to the right upstream service.

---

## NGINX vs Dedicated API Gateways

NGINX is powerful but general-purpose. Dedicated API gateways add more features out of the box:

```
                   NGINX        Kong         AWS API GW   Traefik
                   ──────────   ──────────   ──────────   ──────────
Reverse proxy      ✓            ✓            ✓            ✓
Load balancing     ✓            ✓            ✓            ✓
SSL termination    ✓            ✓            ✓            ✓
Rate limiting      ✓ (basic)    ✓ (rich)     ✓            ✓
Auth / JWT         config       plugin       built-in     middleware
Analytics UI       ✗            ✓            ✓            ✓
Service discovery  ✗            ✓            ✓            ✓ (auto)
```

NGINX is the right choice when you want control and minimal overhead. Kong/Traefik/AWS API GW are better when you want more out-of-the-box.

---

## The Full Picture — Where Everything Fits

```
Internet
   │
   ▼
┌──────────────────────────────────────┐
│           NGINX / API Gateway        │
│                                      │
│  • SSL termination                   │
│  • Auth check (JWT validation)       │
│  • Rate limiting                     │
│  • Request routing by path           │
│  • Load balancing per service        │
│  • Access logging                    │
└─────────────────────┬────────────────┘
                      │
      ┌───────────────┼───────────────┐
      ▼               ▼               ▼
  User Service   Order Service   Payment Service
  (internal,     (internal,      (internal,
   no public      no public       no public
   exposure)      exposure)       exposure)
      │               │               │
      └───────────────┼───────────────┘
                      ▼
                  Database(s)
```

Internal services communicate freely with each other. Only NGINX is exposed to the outside world.

---

## Using NGINX — The Basics

### Installation

```bash
# Ubuntu / Debian
sudo apt install nginx

# macOS
brew install nginx

# Check it's running
sudo systemctl status nginx
```

Once installed, NGINX starts automatically and listens on port 80.

---

### The Config File

Everything in NGINX is controlled by one file:

```
/etc/nginx/nginx.conf          ← main config (rarely edited directly)
/etc/nginx/sites-available/    ← your site configs live here
/etc/nginx/sites-enabled/      ← symlinks to active configs
```

```
┌─────────────────────────────────────────────┐
│              nginx.conf                      │
│                                              │
│  includes sites-enabled/*  ──────────────►  │
│                                     ┌──────────────────────┐
│                                     │  your-site.conf      │
│                                     │  (your actual rules) │
│                                     └──────────────────────┘
└─────────────────────────────────────────────┘
```

---

### Config File Anatomy

NGINX config is built from nested **blocks**. Three you must know:

```
http { }          ← global HTTP settings (already in nginx.conf)
  └── server { }  ← one virtual host (one domain or port)
        └── location { }  ← rule for a specific URL path
```

```nginx
http {
    server {
        listen 80;                    # which port to listen on
        server_name myapp.com;        # which domain this applies to

        location / {                  # match ALL paths
            ...
        }

        location /api/ {              # match only /api/* paths
            ...
        }
    }
}
```

Think of `server` as "which door", and `location` as "what to do once inside".

---

### Use Case 1 — Serve Static Files

You have an `index.html` on disk and want NGINX to serve it.

```
Client                NGINX                Disk
──────                ─────                ────
  │                     │                   │
  │── GET /index.html ──►│                   │
  │                     │── read file ──────►│
  │                     │◄── file contents ──│
  │◄── 200 OK ──────────│                   │
```

```nginx
server {
    listen 80;
    server_name myapp.com;

    root /var/www/myapp;     # where your files live on disk
    index index.html;

    location / {
        try_files $uri $uri/ =404;
        # try the exact file → try as directory → return 404
    }
}
```

```
File system:
  /var/www/myapp/
  ├── index.html      ← GET /        serves this
  ├── about.html      ← GET /about   serves this
  └── assets/
      └── style.css   ← GET /assets/style.css  serves this
```

---

### Use Case 2 — Reverse Proxy to Your App

Your Node/Python/Go app runs on port 3000 (localhost only). NGINX receives public traffic on port 80 and forwards it.

```
Internet              NGINX                 Your App
────────              ─────                 ────────
  │                     │                      │
  │── GET /api/users ──►│                      │
  │                     │── forward request ──►│ :3000
  │                     │◄── response ─────────│
  │◄── response ────────│                      │
```

```nginx
server {
    listen 80;
    server_name myapp.com;

    location / {
        proxy_pass http://localhost:3000;   # forward everything to your app
        proxy_set_header Host $host;        # pass the original Host header
        proxy_set_header X-Real-IP $remote_addr;  # pass client's real IP
    }
}
```

Your app never needs to know about NGINX. It just sees a normal HTTP request on port 3000.

#### `proxy_set_header` — Passing Context to Your App

When nginx forwards a request, it modifies some headers by default. `proxy_set_header` lets you control exactly what the upstream sees.

```
proxy_set_header   Host   $host;
│                  │      │
│                  │      └─ nginx variable: hostname from the incoming request
│                  └─ the HTTP header to set on the proxied request
└─ directive: set/override a header on the forwarded request
```

**Why you need `Host $host`:** by default nginx sets `Host: 127.0.0.1:3000` (the upstream address). Apps that rely on the `Host` header (multi-tenant apps, redirects, cookie domains) would break. This overrides it with the original hostname.

**`$host` vs similar variables:**

| Variable | Value | When to use |
|---|---|---|
| `$host` | hostname from request, lowercased, port stripped | **Default choice** |
| `$http_host` | raw `Host` header (may include port) | When you need to preserve the port |
| `$server_name` | the `server_name` value in your nginx config | When you want the config name, not the client's |

```
Request: GET / HTTP/1.1
         Host: example.com:8080

$host        → example.com        (port stripped)
$http_host   → example.com:8080   (raw header)
$server_name → whatever is in nginx config's server_name
```

**The standard set of headers for any reverse proxy:**

```nginx
location / {
    proxy_pass          http://localhost:3000;

    proxy_set_header    Host              $host;
    proxy_set_header    X-Real-IP         $remote_addr;
    proxy_set_header    X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto $scheme;
}
```

| Header | Purpose |
|---|---|
| `Host $host` | Tell upstream which domain was requested |
| `X-Real-IP $remote_addr` | Tell upstream the client's real IP |
| `X-Forwarded-For $proxy_add_x_forwarded_for` | Chain of IPs across multiple proxies |
| `X-Forwarded-Proto $scheme` | Tell upstream if original request was `http` or `https` |

---

### Use Case 3 — Split Traffic by Path

Different URL paths go to different services.

```
  /api/*   ──────────────► Backend App  :3000
  /*       ──────────────► Static Files /var/www
```

```nginx
server {
    listen 80;
    server_name myapp.com;

    # API requests go to the Node app
    location /api/ {
        proxy_pass http://localhost:3000;
    }

    # Everything else is served as static files
    location / {
        root /var/www/myapp;
        try_files $uri $uri/ =404;
    }
}
```

```
GET /api/users      ──► Node app handles it
GET /index.html     ──► NGINX serves the file directly
GET /assets/app.js  ──► NGINX serves the file directly
```

Static files never hit your app — much faster.

---

### Activating Your Config

```bash
# 1. Write your config
sudo nano /etc/nginx/sites-available/myapp

# 2. Enable it (create a symlink)
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/

# 3. Test for syntax errors BEFORE reloading
sudo nginx -t

# 4. Reload (zero downtime — active connections are not dropped)
sudo systemctl reload nginx
```

```
nginx -t output:

  nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
  nginx: configuration file /etc/nginx/nginx.conf test is successful

Always run this before reload. A bad config can crash NGINX.
```

---

### Essential Commands

```
sudo systemctl start nginx      ← start
sudo systemctl stop nginx       ← stop
sudo systemctl reload nginx     ← reload config (no downtime)
sudo systemctl restart nginx    ← full restart (brief downtime)
sudo nginx -t                   ← test config syntax
sudo nginx -T                   ← print full resolved config

tail -f /var/log/nginx/access.log   ← watch live traffic
tail -f /var/log/nginx/error.log    ← watch errors
```

---

### Config Decision Map

```
What do you need?
│
├── Serve HTML/CSS/JS files from disk?
│       └── Use: root + try_files
│
├── Forward requests to a local app (Node, Python, Go)?
│       └── Use: proxy_pass http://localhost:PORT
│
├── Split traffic by URL path?
│       └── Use: multiple location blocks
│
└── Multiple domains on the same server?
        └── Use: multiple server blocks, each with its own server_name
```

---

## Key Takeaways

- NGINX is a web server that doubles as reverse proxy, load balancer, and API gateway
- A **reverse proxy** hides backend servers from clients — clients only talk to NGINX
- **Load balancing** distributes traffic across multiple instances of the same service
- **SSL termination** keeps certificate management centralized, apps run plain HTTP internally
- An **API gateway** is a reverse proxy with routing, auth, rate limiting, and logging baked in — the single entry point for a microservices system
- NGINX can act as an API gateway via `location` blocks; dedicated tools (Kong, Traefik) add more features at the cost of complexity
