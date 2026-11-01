#!/usr/bin/env bash
# Runs the Go and Node examples against a throwaway `slipway all --dev`, on a free port, with a real API token, and
# checks that a wrong token is refused.
#
# SLIPWAY_BIN           the server binary (required)
# SLIPWAY_DATABASE_URL  Postgres; without it, a container started with $CONTAINER (default podman) and removed on exit
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${SLIPWAY_BIN:?set SLIPWAY_BIN to the slipway binary}"
SLIPWAY_BIN="$(realpath "$SLIPWAY_BIN")"
CONTAINER="${CONTAINER:-podman}"

WORK="$(mktemp -d -t slipway-sdk-examples.XXXXXX)"
SRV_PID=""
PG_CTR=""
cleanup() {
  if [ -n "$SRV_PID" ]; then kill "$SRV_PID" 2>/dev/null || true; wait "$SRV_PID" 2>/dev/null || true; fi
  if [ -n "$PG_CTR" ]; then "$CONTAINER" rm -f "$PG_CTR" >/dev/null 2>&1 || true; fi
  rm -rf "$WORK"
}
trap cleanup EXIT INT TERM HUP

if [ -z "${SLIPWAY_DATABASE_URL:-}" ]; then
  PG_CTR="$("$CONTAINER" run -d --rm -e POSTGRES_USER=slipway -e POSTGRES_PASSWORD=slipway -e POSTGRES_DB=slipway \
    -p 127.0.0.1::5432 docker.io/library/postgres:17-alpine)"
  pg_port="$("$CONTAINER" port "$PG_CTR" 5432/tcp | head -n1 | sed 's/.*://')"
  # Over TCP: the image's init server answers on the socket only, and then restarts.
  for _ in $(seq 1 60); do
    if "$CONTAINER" exec "$PG_CTR" pg_isready -h 127.0.0.1 -U slipway >/dev/null 2>&1; then break; fi
    sleep 1
  done
  export SLIPWAY_DATABASE_URL="postgres://slipway:slipway@127.0.0.1:$pg_port/slipway?sslmode=disable"
fi

PORT="$(node -e 'const s=require("net").createServer();s.listen(0,"127.0.0.1",()=>{console.log(s.address().port);s.close()})')"
URL="http://127.0.0.1:$PORT"

# --dev only provides what is not configured: drop what the environment may set, so the embedded services are used.
unset SLIPWAY_NATS_URL SLIPWAY_CACHE_URL SLIPWAY_BLOB_ENDPOINT SLIPWAY_BLOB_BUCKET SLIPWAY_BLOB_ACCESS_KEY SLIPWAY_BLOB_SECRET_KEY
(cd "$WORK" && SLIPWAY_LISTEN="127.0.0.1:$PORT" SLIPWAY_BASE_URL="$URL" SLIPWAY_BLOB_LOCAL_DIR="$WORK/blob" \
  SLIPWAY_RATE_LIMIT=off SLIPWAY_LOG_LEVEL=warn SLIPWAY_LOG_FORMAT=text \
  exec "$SLIPWAY_BIN" all --dev) >"$WORK/server.log" 2>&1 &
SRV_PID=$!
for _ in $(seq 1 120); do
  curl -fsS "$URL/readyz" >/dev/null 2>&1 && break
  kill -0 "$SRV_PID" 2>/dev/null || { cat "$WORK/server.log"; echo "the server exited" >&2; exit 1; }
  sleep 1
done
curl -fsS "$URL/readyz" >/dev/null || { cat "$WORK/server.log"; echo "the server never became ready" >&2; exit 1; }

# A session from signing up, then an API token from that session. Cookie-authenticated mutations echo the CSRF cookie.
EMAIL="sdk-example@example.com"
rpc() { # method, JSON body
  curl -fsS -b "$WORK/jar" -c "$WORK/jar" -H "Content-Type: application/json" -H "X-CSRF-Token: ${CSRF:-}" \
    "$URL/slipway.v1.IdentityService/$1" -d "$2"
}
rpc Signup "{\"email\":\"$EMAIL\",\"password\":\"correct horse battery staple\",\"name\":\"SDK example\",\"orgName\":\"SDK example\",\"orgSlug\":\"sdk-example\"}" >/dev/null
CSRF="$(awk '$6 == "slipway_csrf" { print $7 }' "$WORK/jar")"
[ -n "$CSRF" ] || { echo "signing up set no CSRF cookie" >&2; exit 1; }
TOKEN="$(rpc CreateApiToken '{"name":"sdk-example"}' | node -pe 'JSON.parse(require("fs").readFileSync(0)).secret')"
[ -n "$TOKEN" ] && [ "$TOKEN" != undefined ] || { echo "no token came back" >&2; exit 1; }

check() { # name, output
  case "$2" in
    *"user=$EMAIL method=token"*) echo "$1: $2" ;;
    *) echo "$1: unexpected output: $2" >&2; exit 1 ;;
  esac
}

export SLIPWAY_URL="$URL"
(cd "$ROOT/examples/go" && go build -o "$WORK/example-go" .)
(cd "$ROOT/ts" && npm ci --ignore-scripts --no-audit --no-fund >/dev/null && npm run --silent build)
(cd "$ROOT/examples/node" && npm install --ignore-scripts --no-audit --no-fund --no-package-lock >/dev/null && npm run --silent build)

check go "$(SLIPWAY_TOKEN="$TOKEN" "$WORK/example-go")"
check node "$(cd "$ROOT/examples/node" && SLIPWAY_TOKEN="$TOKEN" node dist/main.js)"

# Proves the helpers send what they were given: the same calls with a wrong token must fail.
if SLIPWAY_TOKEN="sk_wrong" "$WORK/example-go" >/dev/null 2>&1; then
  echo "go: a wrong token was accepted" >&2; exit 1
fi
if (cd "$ROOT/examples/node" && SLIPWAY_TOKEN="sk_wrong" node dist/main.js >/dev/null 2>&1); then
  echo "node: a wrong token was accepted" >&2; exit 1
fi
echo "a wrong token is refused by both"
