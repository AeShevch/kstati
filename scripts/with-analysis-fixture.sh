#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if curl -sS --max-time 1 -o /dev/null http://127.0.0.1:48731/ 2>/dev/null; then
    echo 'Port 48731 already has a listener.' >&2
    exit 1
fi
npm --prefix "$repo_root/backend" run build
KSTATI_ANALYSIS_FIXTURE=1 NODE_ENV=development node "$repo_root/backend/dist/src/main.js" &
fixture_pid=$!
cleanup() {
    kill "$fixture_pid" 2>/dev/null || true
    wait "$fixture_pid" 2>/dev/null || true
}
trap cleanup EXIT
for attempt in {1..30}; do
    kill -0 "$fixture_pid"
    if curl -fsS --max-time 1 -o /dev/null -H 'Content-Type: application/json' \
        --data '{"text":"Fixture readiness","today":"2026-01-01"}' \
        http://127.0.0.1:48731/v1/memory-analysis 2>/dev/null; then
        "$@"
        exit
    fi
    sleep 1
done
echo 'Local analysis fixture did not start.' >&2
exit 1
