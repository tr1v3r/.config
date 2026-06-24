# Karakeep

Self-hosted **bookmark-everything** app (links, notes, images) with AI-based
automatic tagging, full-text search, and web-page archiving (HTML + screenshot).
Single source of truth on the home server; every device (browser extension,
phone app, CLI, bookmarklet) is a client that reaches it over Tailscale.

## Stack

Three containers (no host networking — they resolve each other by Docker
service-name DNS):

| Container     | Image                                  | Role                             |
| ------------- | -------------------------------------- | -------------------------------- |
| `web`         | `ghcr.io/karakeep-app/karakeep:0.32.0` | App + workers, published `:3000` |
| `chrome`      | `gcr.io/zenika-hub/alpine-chrome:124`  | Headless Chromium for crawl/screenshot |
| `meilisearch` | `getmeili/meilisearch:v1.41.0`         | Full-text search index           |

Data lives in named docker volumes (`data` + `meilisearch`). AI tagging comes
from a **standalone Ollama** on the home server via its OpenAI-compatible
endpoint (`http://<server-tailscale-name>:11434/v1`).

## Deploy (home server)

```bash
git crypt unlock                              # decrypt .env
# Replace <server-tailscale-name> in .env (NEXTAUTH_URL, OPENAI_BASE_URL)
docker compose up -d
```

> **Fill the placeholders BEFORE the first `up`.** Karakeep validates env via a
> Zod schema at DB-migration time; the literal `<server-tailscale-name>` token
> fails the `url` check and the `web` container never starts (ZodError on
> `NEXTAUTH_URL` / `OPENAI_BASE_URL`, `init-db-migration` exits 1). Use the
> server's Tailscale MagicDNS name or `100.x` IP in both URLs.

Then open `http://<server-tailscale-name>:3000`, create the first (only) user,
and set `DISABLE_SIGNUPS=true` in `.env`, then `docker compose up -d` again.

Reach it from any device at `http://<server-tailscale-name>:3000` over Tailscale.
No reverse proxy / TLS — Tailscale is WireGuard-encrypted end to end.

## AI tagging (Ollama contract)

Pull the model on the Ollama host: `ollama pull gemma3`. Tagging is automatic
once `OPENAI_BASE_URL` resolves. `INFERENCE_TEXT_MODEL=gemma3` runs on CPU;
`INFERENCE_IMAGE_MODEL=llava` (commented) needs a GPU to be usable. The Ollama
service itself is configured separately (follow-up spec).

## Data & backup

State is in the named volumes `karakeep_data` (DB + assets) and
`karakeep_meilisearch` (search index). Back them up with:

```bash
docker run --rm -v karakeep_data:/src:ro -v "$PWD":/dst alpine \
  tar czf /dst/karakeep-data-$(date +%F).tar.gz -C /src .
```

Karakeep also has a built-in backup REST API. Restore: stop the stack → restore
the volume(s) → `docker compose up -d` (DB migration runs on startup).

## Why no `network_mode: host`?

Unlike `emby`/`bt` (single-container), Karakeep is multi-container and relies on
the bridge network's service-name DNS. Host networking breaks `chrome` and
`meilisearch` resolution. The published `0.0.0.0:3000` already reaches Tailscale.
