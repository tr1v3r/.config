# Pi-hole v6

Self-hosted DNS + ad-blocker (Pi-hole v6), deployed via Docker. A parallel
alternative to the [`adguard-home/`](../adguard-home/) setup — same job
(network-wide ad blocking + managed DNS), different engine. **Run only one of
the two at a time** (they both want system DNS on :53); this dir exists so the
config is portable and version-controlled regardless of which engine you pick.

| | Pi-hole (here) | AdGuard Home (`../adguard-home/`) |
|---|---|---|
| Container | `pihole` | `adguardhome` |
| DNS host port | `127.0.0.1:8063` | `127.0.0.1:8053` |
| Web UI host port | `127.0.0.1:8064` | `127.0.0.1:8054` |
| Config | `pihole.toml` + `FTLCONF_*` env | `conf/AdGuardHome.yaml` |
| Blocklists | `gravity.db` (seed via `seed-adlists.sh`) | filters in config |

## Files

| Path | Tracked? | Purpose |
|------|----------|---------|
| `docker-compose.yml` | yes | Base: Mac local (`127.0.0.1`, ports 8063/8064). |
| `docker-compose.home.yml` | yes | Override: home Linux host (`network_mode: host`). |
| `.pihole.env` | **git-crypt** | `FTLCONF_webserver_api_password` (plaintext, encrypted at rest). |
| `seed-adlists.sh` | yes | One-shot: add StevenBlack + HaGeZi lists and rebuild gravity. |
| `etc-pihole/`, `etc-dnsmasq.d/` | gitignored | Runtime state (`pihole.toml`, `gravity.db`). Created by the container. |

## Prerequisites

- Docker runtime (Docker Desktop / OrbStack).
- `git-crypt unlock` on a fresh clone to materialize `.pihole.env`.
- The `dns_*` zsh helpers (in `zsh/mac.zsh`) are backend-aware: prefix with
  `DNS_BACKEND=pihole` to target this container.

## First-run credentials

The Web UI password is pre-set via `.pihole.env` (no setup wizard):

- user: _(none — Pi-hole v6 uses just a password)_
- password: **change on first login** (Web UI → Login → change password)

## Scenario 1 — MacBook local

```sh
cd ~/.config/pihole
docker compose up -d                 # boots turnkey (password from .pihole.env)
./seed-adlists.sh                    # one-shot: add blocklists + build gravity (~1min)
open http://localhost:8064           # log in, change password

dig -p 8063 +short doubleclick.net @127.0.0.1   # -> 0.0.0.0 (blocked)
DNS_BACKEND=pihole dns_status        # show service/container + probe :8063
```

DNS is on host `:8063` and the Web UI on `:8064` (both `127.0.0.1`). See the
Zscaler note below for why neither uses the default port.

> `dns_up` / `dns_down` (zsh) redirect the **system** DNS to `127.0.0.1`, which
> only works when the backend serves `:53` (clean network / at home). With DNS
> on `:8063` here they abort with a hint — use `dig -p 8063 @127.0.0.1`.

## Scenario 2 — Home (generic Docker host)

```sh
# on the Linux home host (after git-crypt unlock):
docker compose -f docker-compose.yml -f docker-compose.home.yml up -d
./seed-adlists.sh                    # same seed step
```

Then give the host a static LAN IP, set the router's DHCP DNS to it, and
reconnect devices. Manage at `http://<host-LAN-IP>:80`.

> `network_mode: host` binds Pi-hole's `:53` + `:80` directly. Don't co-locate
> with AdGuard on the same home host — both claim `:53`.

## Zscaler / corporate-security Macs

A corporate security agent (e.g. **Zscaler**) resets container-forwarded HTTP on
common web ports (`3000`, `8080`, …) and intercepts `:53`. So this setup
publishes DNS on `8063` and the Web UI on `8064` (both `127.0.0.1` — not exposed
to the LAN; `0.0.0.0` is not needed). DNS is reachable via
`dig -p 8063 @127.0.0.1`; the Mac's *system* DNS can't be redirected to a local
resolver (the resolver only queries `:53`, which the agent owns), so `dns_up`
is a no-op here. Filtering still works — verify it over the docker network:

```sh
docker run --rm --network pihole_default alpine \
  sh -c 'apk add -q bind-tools && dig +short doubleclick.net @pihole'
# -> 0.0.0.0   (filtering works)
```

## Tuning upstreams / lists

- **Upstreams**: edit `FTLCONF_dns_upstreams` in `docker-compose.yml`, then
  `docker compose up -d`. (CN-friendly encrypted options: `tls://dns.alidns.com`,
  `tls://dot.pub`.)
- **Lists**: add/remove via Web UI (Group Management → Adlists) and Update
  Gravity, or re-run `seed-adlists.sh` after editing its `LISTS`.

## Troubleshooting

- **Web UI shows a password prompt but login fails**: `.pihole.env` may not have
  decrypted — `git-crypt status .pihole.env` should show `encrypted` locally and
  the file should contain `FTLCONF_webserver_api_password=…`. Reset with
  `docker compose exec pihole pihole setpasswd <new>`.
- **`dig -p 8063` returns real IPs instead of `0.0.0.0`**: gravity hasn't been
  built — run `./seed-adlists.sh` (or Web UI → Update Gravity).
- **Port already in use**: another DNS/UI holds it; check
  `docker ps` and `sudo lsof -i :8063 -i :8064`.
