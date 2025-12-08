# Loopy

Scoped API proxy for [loops.so](https://loops.so). Allows teams to generate project-specific API keys with limited permissions instead of sharing a single unscoped loops.so key.

## Auth

- OIDC via [HCA](https://auth.hackclub.com/docs/oidc-guid)
- Staff access controlled by hardcoded `hca_id` allowlist (temporary until HCA roles API exists)

## Scopes

| Scope | Description |
|-------|-------------|
| `transactional:send` | Proxy `POST /api/v1/transactional` and SMTP relay |

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
