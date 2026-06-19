#!/usr/bin/env sh
# Seed Pi-hole v6 blocklists (turnkey) via the v6 API.
#
# v6 ships StevenBlack as a default adlist AND builds gravity on first start, so
# basic blocking already works out of the box — this script ensures BOTH the
# StevenBlack and HaGeZi lists are present (parity with the AdGuard setup) and
# rebuilds gravity. Safe to re-run: duplicate adds are tolerated.
#
# Run once after `docker compose up -d`, from this directory:
#   cd ~/.config/pihole && ./seed-adlists.sh
#
# Requires on the host: curl, python3 (to parse the JSON session). macOS ships
# both; Linux: apt install curl python3.

set -eu

BASE=http://127.0.0.1:8064

# password lives in .pihole.env (git-crypt): FTLCONF_webserver_api_password=...
. ./.pihole.env
PW="${FTLCONF_webserver_api_password:?no password in .pihole.env}"

LISTS='
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/pro.txt
'

echo "Authenticating to Pi-hole API..."
RESP=$(curl -s --noproxy '*' -X POST "$BASE/api/auth" \
    -H 'Content-Type: application/json' -d "{\"password\":\"$PW\"}")
SID=$(printf '%s' "$RESP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["session"]["sid"])')
CSRF=$(printf '%s' "$RESP" | python3 -c 'import sys,json;print(json.load(sys.stdin)["session"]["csrf"])')

echo "Ensuring adlists are registered..."
for url in $LISTS; do
    # type=block is a query param; address goes in the JSON body.
    # A duplicate address returns an error — tolerated.
    curl -s --noproxy '*' -o /dev/null -X POST "$BASE/api/lists?type=block" \
        -H "sid: $SID" -H "X-CSRF: $CSRF" -H 'Content-Type: application/json' \
        -d "{\"address\":\"$url\"}" || true
done

echo "Rebuilding gravity (downloads + indexes the lists, ~30-60s)..."
docker compose exec -T pihole pihole -g

echo "Done. Verify: dig -p 8063 +short doubleclick.net @127.0.0.1  # -> 0.0.0.0"
