# Deployment Examples (Kamal 2)

**For complete guidelines, see: [VERIFICATION_CHECKLIST.md](../VERIFICATION_CHECKLIST.md#deployment-kamal)**

Deploy with Kamal 2 using Rails 8 optimizations.

## Kamal Configuration

```yaml
# config/deploy.yml
service: papyro

# Use Rails 8 with Ruby 4.0.0
image: papyro/app

# Kamal 2: Multiple servers
servers:
  web:
    hosts:
      - 192.168.1.1
      - 192.168.1.2
    labels:
      traefik.http.routers.papyro.rule: Host(`papyro.com`)
    options:
      network: "private"
  
  # Solid Queue workers
  workers:
    hosts:
      - 192.168.1.3
    cmd: bundle exec rake solid_queue:start
    options:
      network: "private"

# Use SQLite in production (Rails 8)
volumes:
  - "storage:/rails/storage"

# Environment variables
env:
  clear:
    RAILS_ENV: production
    RAILS_LOG_LEVEL: info
    SOLID_QUEUE_CONCURRENCY: 10
  secret:
    - RAILS_MASTER_KEY
    - SECRET_KEY_BASE

# Kamal 2: Healthcheck
healthcheck:
  path: /up
  interval: 10s
  timeout: 5s

# Kamal 2: Asset configuration
asset_path: /rails/public/assets

# Kamal 2: Use Traefik for load balancing
traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt:/letsencrypt"
```

## Deploy Commands

```bash
# Initial setup
kamal setup

# Deploy
kamal deploy

# Check status
kamal app details

# View logs
kamal app logs

# SSH into container
kamal app exec -i bash

# Rollback
kamal app rollback
```

## Rules

Rules live in the checklist:
- [Deployment](../VERIFICATION_CHECKLIST.md#deployment-kamal)
