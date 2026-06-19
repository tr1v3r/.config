# AdGuard Home

Self-hosted DNS + ad-blocker, deployed via Docker. Two scenarios share **one
config** (`conf/AdGuardHome.yaml`, git-crypt encrypted):

1. **MacBook local** — runs in Docker Desktop, takes over this Mac's DNS.
2. **Home** — runs on a Linux host, serves DNS to the whole LAN.

## Why

- Network-wide ad / tracker blocking at the resolver layer (no per-device setup at home).
- Central place to manage upstream DNS, local overrides (`user_rules`), and query log.
- Single portable config version-controlled here.

## Files

| Path                      | Tracked?      | Purpose                                                                     |
| ------------------------- | ------------- | --------------------------------------------------------------------------- |
| `docker-compose.yml`      | yes           | Base: Mac local (binds `127.0.0.1`).                                        |
| `docker-compose.home.yml` | yes           | Override: home Linux host (`network_mode: host`).                           |
| `conf/AdGuardHome.yaml`   | **git-crypt** | Turnkey config (admin user + upstreams + filters).                          |
| `work/`                   | gitignored    | Runtime state (filter cache, querylog, stats DB). Created by the container. |

## Prerequisites

- **Docker runtime**: Docker Desktop or OrbStack. (OrbStack is listed but commented
  out in `zsh/mac.zsh` → `HOMEBREW_PACKAGES`; uncomment to install via brew.)
- **git-crypt**: a fresh clone needs `git-crypt unlock` once to materialize
  `conf/AdGuardHome.yaml`. (`brew install git-crypt` if missing.)
- **macOS DNS helpers**: `dns_up` / `dns_down` / `dns_status` live in `zsh/mac.zsh`.

## First-run credentials

The config ships with a pre-provisioned admin so there is **no web wizard**:

- user: `admin`
- password: **change on first login** (Web UI → Settings → Authentication)

## Scenario 1 — MacBook local

```sh
cd ~/.config/adguard-home
docker compose up -d                 # boots straight into service, no wizard
open http://localhost:8054           # log in, change password (port 8054, see Zscaler note)

dns_up                               # redirect system DNS — only works when ADGUARD_DNS_PORT=53
dig -p 8053 +short doubleclick.net @127.0.0.1   # -> 0.0.0.0 (DNS on host :8053, not :53)
dns_status                           # show service/container + probe the DNS port
```

The Web UI is on **`127.0.0.1:8054`** (→ container `:8080`) and DNS on
**`127.0.0.1:8053`** (→ container `:53`) — both uncommon host ports,
localhost-only. See the Zscaler note for why neither uses the default port.

`dns_up` / `dns_down` (in `zsh/mac.zsh`) redirect the _system_ DNS to
`127.0.0.1`, which only works when AdGuard serves `:53` (clean network / home).
With DNS on `:8053` here they abort with a hint — use `dig -p 8053 @127.0.0.1`.

> **Zscaler / corporate-security Macs:** the agent HTTP-inspects and **resets
> common web ports** (`3000`, `8080`, …) and intercepts `:53`, so the container
> publishes DNS on `8053` and the Web UI on `8054` (both `127.0.0.1` — not
> exposed to the LAN; `0.0.0.0` is **not** needed). DNS is reachable via
> `dig -p 8053 @127.0.0.1`; the Mac's _system_ DNS can't be redirected to a
> local resolver (the resolver only queries `:53`, which the agent owns), so
> `dns_up` is a no-op here. Filtering works (verify via the docker network);
> full system-DNS integration works at home.

## Scenario 2 — Home (generic Docker host)

```sh
# on the Linux home host (after git-crypt unlock):
docker compose -f docker-compose.yml -f docker-compose.home.yml up -d
```

Then make the whole house use it:

1. Give the host a **static LAN IP**.
2. In your router, set the **DHCP DNS server** to that IP.
3. Reconnect devices (or renew DHCP leases) — they now resolve through AdGuard.

Manage at `http://<host-LAN-IP>:8080`.

> `docker-compose.home.yml` uses `network_mode: host`, so AdGuard binds the
> host's `0.0.0.0:53` directly. That mode is Linux-only; the Mac uses explicit
> `127.0.0.1` port mapping from the base file instead.

## Coexistence with clash-verge-rev

- **System-proxy mode (mixed port 9981, current setup)**: apps route proxied
  traffic through clash, but DNS still goes through the OS resolver. Pointing the
  OS DNS at AdGuard Home sends resolution through AdGuard; clash's domain rules
  (`bd_router.yaml`) apply at the connection layer (SNI/host) and are unaffected.
  **The two coexist with no extra work.**
- **TUN mode (if enabled)**: clash creates a virtual NIC and hijacks all traffic
  - DNS, bypassing `127.0.0.1:53`. If you use TUN, either disable clash's DNS
    hijack or point clash's DNS upstream at this AdGuard Home instance.
- `dns_up` preflights port 53 and aborts with a warning if something (e.g. clash
  in a 53-binding config) already holds it.

## Tuning upstreams / filters

Edit `dns.upstream_dns` or the `filters:` list either via the Web UI or directly
in `conf/AdGuardHome.yaml`, then restart the container (`docker compose restart`)
and commit the change (git-crypt re-encrypts on commit).

CN-friendly encrypted upstreams (uncomment in the config):

```
tls://dns.alidns.com      # AliDNS over TLS
tls://dot.pub             # DNSPod over TLS
https://dns.cloudflare.com/dns-query
```

## Troubleshooting

- **`bind: address already in use` on 53**: something holds port 53. `sudo lsof
-i :53`. On macOS it's usually free; clash in TUN mode can occupy it.
- **DNS breaks when container is off**: expected — `dns_up` adds `1.1.1.1` as a
  fallback, but ad-blocking is bypassed while the container is down. Run
  `dns_down` to fully restore DHCP DNS.
- **Web UI unreachable**: `docker compose logs adguardhome`. Confirm the config
  decrypted correctly (`git-crypt status conf/AdGuardHome.yaml`).

### Verifying it's really AdGuard answering

On the Mac, `dig -p 8053 +short doubleclick.net @127.0.0.1` returns `0.0.0.0`
(blocked) and `dig -p 8053 +short example.com @127.0.0.1` returns a real IP.
(At home, DNS is on the standard `:53`, so drop `-p 8053`.) Cross-check in
Web UI → Query Log — every query should appear there.

To bypass the host entirely and prove AdGuard itself works, dig it over the
docker network:

```sh
docker run --rm --network adguard-home_default alpine \
  sh -c 'apk add -q bind-tools && dig +short doubleclick.net @adguardhome'
# -> 0.0.0.0   (filtering works)
```

### Zscaler / corporate security agents (root cause of port-3000/8080 failures)

A corporate security agent (e.g. **Zscaler**) HTTP-inspects and **resets
container-forwarded connections on common web ports** (`3000`, `8080`, …) while
leaving uncommon ports alone. Symptoms, all on the same machine:

- `curl http://127.0.0.1:8080` → `Connection reset by peer`, yet `nc -z 127.0.0.1 8080` succeeds and the container is healthy.
- `curl http://127.0.0.1:8054` (or any uncommon port) → works fine.
- `dig @127.0.0.1` (port `:53`) returns a single hijack IP range (e.g. `30.x.x.x`) and the Query Log stays empty — the agent owns `:53`. Reach AdGuard on `8053` instead: `dig -p 8053 @127.0.0.1`.

So the fix is the **host port**, not the bind address — `127.0.0.1` binding is
fine (your other containers prove it). `docker-compose.yml` publishes the Web UI
on `127.0.0.1:8054 → :8080` (uncommon host port, localhost-only, **no LAN
exposure**). Note OrbStack has a quirk where `HOST:HOST` (same-port) forwarding
fails, hence mapping `8054 → 8080` rather than `8054 → 8054`. Filtering itself
is unaffected (verify via the docker-network command above). The Mac's _system_
DNS can't be redirected to a local resolver while the agent is active; that
integration works at home.
