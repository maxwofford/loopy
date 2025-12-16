# Loopy

Scoped API proxy for [loops.so](https://loops.so). Allows teams to generate project-specific API keys with limited permissions instead of sharing a single unscoped loops.so key.

## Auth

- OIDC via [HCA](https://auth.hackclub.com/docs/oidc-guid)
- Staff access controlled by hardcoded `hca_id` allowlist (temporary until HCA roles API exists)

## Scopes

| Scope | Description |
|-------|-------------|
| `transactional:send` | Proxy `POST /api/v1/transactional` and SMTP relay (port 587) |

## API Key Format

```
auth!USER@PROJECT_DATE.SECRET_KEY
```

Example: `auth!max@highseas_20241207.a1b2c3d4e5f6`

## Schema

### Users
| Column | Type |
|--------|------|
| hca_id | string (unique) |
| email | string |

### ApiKeys
| Column | Type |
|--------|------|
| user_id | fk |
| project | string |
| key_hash | string |
| scopes | string[] |
| revoked_at | datetime (nullable) |

### ApiRequests (audit log)
| Column | Type |
|--------|------|
| api_key_id | fk |
| endpoint | string |
| request_body | jsonb |
| response_status | integer |
| ip_address | string |
| fingerprint | jsonb |
| created_at | datetime |

## IP Fingerprinting

Uses `CF-Connecting-IP` header when behind Cloudflare, falls back to `X-Forwarded-For`, then `request.remote_ip`.

Fingerprint includes: IP, User-Agent, CF-IPCountry (if available).

## Public Key Revocation

`GET /revoke?key=AUTH_KEY` — public page allowing anyone to revoke a leaked key. Sends email notification to key owner via **SES** (not loops.so, to ensure delivery even if loops.so is compromised).

## Deployment

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 80 | Web | Rails HTTP API (proxied through Thruster) |
| 587 | SMTP | SMTP relay with STARTTLS |
| 8080 | Certbot | Let's Encrypt HTTP-01 challenge (only needed during cert generation/renewal) |

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `LOOPS_API_KEY` | Yes | Master loops.so API key for proxying requests |
| `SMTP_PORT` | No | SMTP server port (default: 587) |
| `SMTP_HOST` | No | SMTP server bind address (default: 0.0.0.0) |
| `SMTP_DOMAIN` | No | Domain for TLS certs (e.g., `smtp.loopy.hackclub.com`). If set, enables automatic Let's Encrypt cert generation |
| `SMTP_TLS_CERT` | No | Path to TLS certificate (auto-set when using `SMTP_DOMAIN`) |
| `SMTP_TLS_KEY` | No | Path to TLS private key (auto-set when using `SMTP_DOMAIN`) |
| `CERTBOT_EMAIL` | No | Email for Let's Encrypt notifications (default: admin@hackclub.com) |

### TLS Certificates

When `SMTP_DOMAIN` is set, the SMTP server will automatically:
1. Request a Let's Encrypt certificate on first startup
2. Check for renewal on subsequent startups (renews when < 30 days until expiry)

Certificates are stored in `/etc/letsencrypt` which is configured as a Docker volume for persistence.

**Requirements for automatic TLS:**
- DNS for `SMTP_DOMAIN` must point to your server
- Port 8080 must be accessible from the internet during cert generation/renewal

### SMTP Client Configuration

Drop-in replacement for loops.so SMTP. For Rails apps:

```ruby
config.action_mailer.smtp_settings = {
  address:         'loopy.hackclub.com',  # Your Loopy host
  port:            587,
  user_name:       'loops',               # Can be any value
  password:        'auth!user@project_date.secret',  # Loopy API key
  authentication:  'plain',
  enable_starttls: true
}
```

### Running Locally

```bash
# Install dependencies
bundle install

# Start both web and SMTP servers
bin/dev

# Or run separately:
bin/rails server        # Web on port 3000
bin/smtp_server         # SMTP on port 587
```

### Coolify Deployment

Deploy using `docker-compose.yml` which runs both services:
- `web`: Rails server (HTTP API) on port 80
- `smtp`: SMTP relay server on ports 587/8080

**Required environment variables in Coolify:**

```bash
RAILS_MASTER_KEY=<from config/master.key>
DATABASE_URL=postgres://...
LOOPS_API_KEY=<your loops.so API key>
SMTP_DOMAIN=smtp.loopy.hackclub.com
CERTBOT_EMAIL=admin@hackclub.com
POSTGRES_PASSWORD=<secure password>
```

**Volumes (auto-configured via docker-compose):**
- `letsencrypt` → persists TLS certificates
- `postgres_data` → persists database

**DNS setup:**
- `loopy.hackclub.com` → web service (port 80)
- `smtp.loopy.hackclub.com` → SMTP service (port 587)
