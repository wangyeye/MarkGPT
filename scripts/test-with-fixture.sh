#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/check-environment.sh
stage="$(mktemp -d /private/tmp/markgpt-fixture.XXXXXX)"
python3 scripts/mock-provider.py "$stage/port" &
fixture_pid=$!
trap 'kill "$fixture_pid" 2>/dev/null || true; rm -rf "$stage"' EXIT
for attempt in {1..50}; do [[ -f "$stage/port" ]] && break; sleep .1; done
[[ -f "$stage/port" ]]
export MARKGPT_FIXTURE_URL="http://127.0.0.1:$(cat "$stage/port")/v1"
export MARKGPT_DATA_DIR="$stage/data"
./scripts/test.sh
./scripts/render-test.sh
