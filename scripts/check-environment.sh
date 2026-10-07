#!/bin/bash
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo 'macOS required'; exit 1; }
for tool in swift xcrun python3 codesign ditto plutil; do command -v "$tool" >/dev/null || { echo "Missing $tool"; exit 1; }; done
xcrun --show-sdk-path >/dev/null
python3 - <<'CHECK'
import sys, platform, subprocess, re
if sys.version_info < (3,9): raise SystemExit('Python 3.9+ required')
if tuple(map(int,platform.mac_ver()[0].split('.')[:2])) < (13,0): raise SystemExit('macOS 13+ required')
version=subprocess.check_output(['swift','--version'],text=True)
match=re.search(r'Swift version (\d+)\.(\d+)',version)
if not match or tuple(map(int,match.groups())) < (5,9): raise SystemExit('Swift 5.9+ required')
CHECK
echo 'Environment ready: macOS, Swift, SDK, Python 3 and packaging tools'
