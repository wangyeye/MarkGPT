#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/check-environment.sh
[[ -d dist/MarkGPT.app ]] || ./scripts/build.sh
open dist/MarkGPT.app
