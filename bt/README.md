# qBittorrent Enhanced Edition

Dockerized **qBittorrent-Enhanced-Edition** for BT / magnet / **PT (private
tracker)** downloads, deployed via Docker. One config dir, two scenarios: run it
locally on the MacBook, or on the home server and control it from the MacBook
over **Tailscale**. The Enhanced fork auto-updates public trackers and bans
Xunlei/Thunder-style anti-leech clients — the de-facto client for PT sites — and
handles plain BT/magnet just as well.

| | Docker qBEE (here) | Native Mac qBittorrent (`../qBittorrent/`) |
|---|---|---|
| Engine | Enhanced (anti-leech, auto tracker) | stock |
| Runs on | server **and** Mac (same compose) | Mac only |
| Web UI | yes (`127.0.0.1:8088` / `<server>:8088`) | disabled |
| BT port | `6881` | `28096` |
| Network | **direct** (no proxy — correct for PT) | via Clash `127.0.0.1:1087` |
| Remote control | Tailscale | local only |

## Files

| Path | Tracked? | Purpose |
|------|----------|---------|
| `docker-compose.yml` | yes | Base: Mac local (`127.0.0.1`, WebUI `8088`, BT `6881`). |
| `docker-compose.home.yml` | yes | Override: home Linux host (`network_mode: host`). |
| `.qbittorrent.env.example` | yes | Template: `PUID` / `PGID` / `TZ` / `WEBUIPORT`. |
| `.qbittorrent.env` | gitignored | Per-machine copy (UIDs differ Mac vs server). |
| `config/` | gitignored | Runtime state — `config/qBittorrent/config/qBittorrent.conf` (incl. WebUI password hash). |
| `downloads/` | gitignored | Download destination (symlink to your storage if you like). |

## Prerequisites

- Docker runtime (Docker Desktop / OrbStack on Mac; Docker Engine on the server).
- **Tailscale** on both the server and the MacBook, logged into the same tailnet
  (`brew install tailscale` on Mac; see https://tailscale.com/setup for the
  server). This is how the MacBook reaches the server's Web UI remotely.
- No `git-crypt unlock` needed here — this dir holds no encrypted secret (the
  WebUI password is a hash in the runtime `qBittorrent.conf`, set on first login).

## First-run credentials

The container logs a one-time temporary WebUI password on first boot:

```sh
docker compose logs qbittorrentee | grep -iE 'password|密码'
```

- user: **admin**
- password: the temp string from the logs

Log in, then **Options → WebUI → Authentication** → set a real username/password.
The hash persists in `config/qBittorrent/config/qBittorrent.conf`.

## Scenario 1 — MacBook local

```sh
cd ~/.config/bt
cp .qbittorrent.env.example .qbittorrent.env
sed -i '' "s/^PUID=.*/PUID=$(id -u)/; s/^PGID=.*/PGID=$(id -g)/" .qbittorrent.env   # macOS sed

# optional: reuse your existing external video mount instead of a local dir
ln -s /Volumes/Gamma/Videos downloads

docker compose up -d
docker compose logs qbittorrentee | grep -iE 'password|密码'   # temp WebUI password
open http://localhost:8088                              # log in, set a real password
```

WebUI on `127.0.0.1:8088`, BT incoming on `6881`. See the Zscaler note below for
why neither uses a common port like `8080`.

## Scenario 2 — Home server (controlled from the MacBook)

```sh
# on the Linux home host:
cd ~/.config/bt
cp .qbittorrent.env.example .qbittorrent.env
sed -i "s/^PUID=.*/PUID=$(id -u)/; s/^PGID=.*/PGID=$(id -g)/" .qbittorrent.env   # GNU sed
docker compose -f docker-compose.yml -f docker-compose.home.yml up -d
docker compose logs qbittorrentee | grep -iE 'password|密码'
```

Then from the MacBook (both on Tailscale):

```sh
open http://<server-tailscale-name>:8088   # e.g. http://homeserver:8088
```

Downloads land in `~/.config/bt/downloads/` on the server. Forward
TCP/UDP `6881` on the home router to the server for a connectable BT port (see
PT tuning). Do **not** forward `8088` — keep the Web UI off the public WAN.

> `network_mode: host` makes qBittorrent listen on the host's interfaces
> directly, including `tailscale0`. Coexists with the native Mac qBittorrent
> (different BT port `6881` vs `28096`) — run both, or retire the native app.

## PT tuning (read before adding private-tracker torrents)

1. **Pin the image tag to a version your PT site whitelists.** Edit `image:` in
   `docker-compose.yml`. Available tags:
   https://hub.docker.com/r/superng6/qbittorrentee/tags (this dir defaults to
   `5.2.1.10`, the latest qBEE). Many PT sites only allow specific versions
   (often `4.x`); confirm the client + version string appears in the site's
   client whitelist **before** adding PT torrents — a non-whitelisted client
   won't connect and can get you banned. Don't use `:latest`.
2. **DHT / PEX / LSD: keep ON globally** (public BT needs them). PT `.torrent`
   files carry a `private` flag that makes qBittorrent auto-disable DHT/PEX/LPD
   for *that* torrent, so your passkey can't leak to public DHT. Never convert a
   private torrent into a magnet or re-announce it elsewhere.
3. **Anonymous Mode: keep OFF** — on PT it can trip client-detection bans.
4. **Encryption: "Allow encryption" / "Prefer encryption"** is fine; "Force"
   shrinks your PT peer pool.
5. **Connectability: forward `6881` TCP+UDP** on the router to the server → green
   status → healthier ratio, no H&R upload failures.
6. **(Optional, not included here)** add a `PeerBanHelper` sidecar container for
   stronger PT anti-leech than the Enhanced fork alone.

## Tailscale access

Plain `http://<server-tailscale-name>:8088` is already end-to-end encrypted by
the WireGuard tunnel — no TLS needed. For an `https://<name>.ts.net` URL with a
real cert, run on the server: `tailscale serve --bg --https=443 http://localhost:8088`
(see https://tailscale.com/kb/1248/tailscale-serve). Entirely optional.

## Zscaler / corporate-security Macs

A corporate agent (e.g. **Zscaler**) resets container-forwarded HTTP on common
web ports (`8080`, `3000`, …) and intercepts `:53`. So the WebUI runs on `8088`
and binds to `127.0.0.1` (no `0.0.0.0` needed locally). BT peer-wire on `6881`
isn't HTTP and isn't affected, though incoming peers may still be blocked by a
corporate NAT/firewall — at home it's unimpeded.

## Troubleshooting

- **Downloads owned by `root` / permission denied**: `PUID`/`PGID` in
  `.qbittorrent.env` don't match your user. Set them to `id -u` / `id -g`, then
  `docker compose down && up -d` (the entrypoint re-applies the mapping).
- **WebUI shows a temp password on every restart**: you haven't set a permanent
  one — Options → WebUI → Authentication → set username/password.
- **`Port 8088/6881 already in use`**: `docker ps` and
  `sudo lsof -i :8088 -i :6881`. The native Mac qBittorrent uses `28096` (no
  clash) — something else holds the port.
- **Connection status "firewalled"**: the router isn't forwarding `6881`, or (on
  a corporate Mac) incoming BT is blocked. At home, port-forward `6881` TCP+UDP.
- **`WEBUIPORT` change had no effect**: it's applied on first boot only — stop
  the container, delete `config/`, edit `.qbittorrent.env`, then `up -d`. **This
  wipes `qBittorrent.conf` (password, torrents) — back it up first.**
- **PT torrent won't connect / "client not allowed"**: the pinned image version
  isn't on the site whitelist — switch the tag to a whitelisted one (PT tuning #1).
