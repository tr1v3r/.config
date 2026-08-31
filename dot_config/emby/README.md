# Emby

Dockerized **Emby** — a polished self-hosted media server: it auto-scrapes
posters/plot/cast from TheMovieDb/TheTVDB and streams your library to any device.
(Closed-core; some advanced features — hardware transcoding, mobile downloads —
need an **Emby Premiere** subscription.) It is a sibling to the
[`bt/`](../bt/) download service and **mounts qBittorrent's `downloads/`
read-only as `/media`** — so whatever finishes downloading in `bt/` shows up here
automatically. Same dual-scenario pattern as `bt/`: run locally on the MacBook,
or on the home server and watch from the MacBook over Tailscale.

|              | Emby (here)                | Jellyfin            | Plex                                  |
| ------------ | -------------------------- | ------------------- | ------------------------------------- |
| License      | closed-core, Premiere paid | FOSS, fully free    | closed-core, Plex Pass paid + account |
| Self-host    | yes                        | yes                 | yes (phones home)                     |
| Image        | `emby/embyserver`          | `jellyfin/jellyfin` | `plexinc/pms-docker`                  |
| Default port | `8096`                     | `8096`              | `32400`                               |

## Files

| Path                         | Tracked?   | Purpose                                                    |
| ---------------------------- | ---------- | ---------------------------------------------------------- |
| `docker-compose.yml`         | yes        | Base: Mac, WebUI `8096` on all interfaces (LAN-reachable). |
| `docker-compose.home.yml`    | yes        | Override: home Linux host (`network_mode: host`).          |
| `config/`                    | gitignored | Emby config, metadata DB, generated posters, transcodes.   |
| `../bt/downloads` (external) | —          | qBittorrent's downloads, mounted read-only as `/media`.    |

## Prerequisites

- Docker runtime (Docker Desktop / OrbStack on Mac; Docker Engine on the server).
- **`bt/` set up first** — `/media` is a read-only mount of `../bt/downloads`.
  Whatever qBittorrent downloads there is what Emby serves.
- **Tailscale** on both the server and the MacBook (same tailnet) to watch the
  server's library remotely.
- No `git-crypt` / `.env` needed here — Emby has no per-machine secret and the
  official image needs no `PUID/PGID` (it runs as root and reads everything).

## First-run setup

Emby runs a setup wizard on first launch:

1. Open the Web UI → it walks you through initial setup.
2. Create the **admin account** (username + password of your choice; Emby Connect
   is optional).
3. **Add a media library**: pick type (Movies / TV Shows / Music / Mixed) →
   folder `/media`. Add one library per type.
4. Set **preferred metadata language** to `Chinese` (zh), country `China` — so
   posters/plot scrape in Chinese. Finish.

## Scenario 1 — MacBook local

```sh
cd ~/.config/emby
docker compose up -d
open http://localhost:8096     # walk the setup wizard, add libraries pointing at /media
```

Stream in a browser on this Mac at `http://localhost:8096`. From a phone or TV
on the same Wi-Fi, point the Emby app at `http://<mac>.local:8096` (Bonjour,
stable across DHCP IP changes) or the Mac's LAN IP `http://<mac-lan-ip>:8096`.
Find yours with `scutil --get LocalHostName` and `ipconfig getifaddr en0`.

## Scenario 2 — Home server (watch from the MacBook)

```sh
# on the Linux home host:
cd ~/.config/emby
docker compose -f docker-compose.yml -f docker-compose.home.yml up -d
```

Then from the MacBook (both on Tailscale):

```sh
open http://<server-tailscale-name>:8096   # e.g. http://homeserver:8096
```

> `network_mode: host` makes Emby listen on the host's interfaces directly,
> including `tailscale0`. Don't forward `8096` on the router — keep it off the WAN.

## How it ties to `bt/`

`/media` is a **read-only** bind of `../bt/downloads` (qBittorrent's download
destination on this machine). Finish a torrent in qBittorrent → Emby picks it up
on its next library scan and adds posters/metadata automatically. If on the Mac
you symlinked `bt/downloads → /Volumes/Gamma/Videos`, that's exactly what
`/media` sees. Read-only means Emby can never corrupt your downloads.

## Metadata sources

Built in — no extra setup:

- **TheMovieDb (TMDB)** for movies & show metadata, posters, backdrops.
- **TheTVDB** for episode/season data.
- **Emby's own / Others** (MusicBrainz, TheAudioDB, etc.) for music and fill-in.

Set the language to Chinese (zh) in the wizard or later under
**Dashboard → Libraries → (library) → Metadata downloaders**.

## Tailscale access

Plain `http://<server-tailscale-name>:8096` is already end-to-end encrypted by the
WireGuard tunnel. For an `https://<name>.ts.net` URL with a real cert, run on the
server: `tailscale serve --bg --https=443 http://localhost:8096`. Optional.

## Zscaler / corporate-security Macs

`8096` isn't one of the common web ports a corporate agent intercepts — no
interference expected. It binds to all interfaces (LAN-reachable), so don't
forward `8096` on your router — keep the Web UI off the public WAN.

## Troubleshooting

- **Library empty / new downloads not showing**: confirm qBittorrent actually
  finished files into `../bt/downloads`, then Emby → **Dashboard → Libraries →
  Scan library** (it also auto-scans on a timer). Check the mount:
  `docker compose exec emby ls -la /media`.
- **Bind-mount error mentioning `../bt/downloads`**: `bt/` isn't set up yet, or
  `bt/downloads` is a symlink to a volume that isn't mounted. Set up `bt/` first,
  or mount the real path.
- **Permission denied reading media**: the official `emby/embyserver` image runs
  as root and reads everything; if you switched to `lscr.io/linuxserver/emby`
  (non-root), set `PUID`/`PGID` to your `id -u`/`id -g`.
- **Playback stutters / high CPU**: transcoding is CPU by default. Hardware
  transcoding is an **Emby Premiere** feature — enable it under
  **Dashboard → Playback → Transcoding** if your box supports it and you have a
  Premiere key.
- **Transcodes filling `/config`**: transcodes default to `config/transcodes/`.
  To put them on a dedicated volume, add `- ./transcode:/transcode` to the compose
  `volumes:` and set **Dashboard → Playback → Transcoding → Transcode path** to
  `/transcode`.
- **`Port 8096 already in use`**: `docker ps` and `sudo lsof -i :8096`.
