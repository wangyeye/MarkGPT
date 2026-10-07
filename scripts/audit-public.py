#!/usr/bin/env python3
"""Audit only the independent MarkGPT tracked release sources."""
from pathlib import Path
import subprocess, sys, re
if sys.version_info < (3,9): raise SystemExit('Python 3.9+ required')
root=Path(__file__).resolve().parents[1]
if not (root/'.git').is_dir(): raise SystemExit('Independent MarkGPT Git repository required')
paths=subprocess.check_output(['git','ls-files','-z'],cwd=root).decode().split('\0')
issues=[]
for name in filter(None,paths):
    p=root/name
    if any(x in p.parts for x in ['.build','dist','__pycache__']) or p.name in ['credentials.json','workspace.json','.DS_Store']: issues.append(name+': forbidden file')
    if p.suffix == '.pyc': issues.append(name+': compiled cache forbidden')
    if p.suffix in ['.swift','.py','.sh','.md','.json','.yml']:
        text=p.read_text()
        for pattern in [r'/Users/[A-Za-z0-9_.-]+/',r'gh[pousr]_[A-Za-z0-9]{20,}',r'sk-[A-Za-z0-9_-]{24,}',r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----\r?\n[A-Za-z0-9+/=]{20}']:
            if re.search(pattern,text): issues.append(name+': possible private data')
if issues: raise SystemExit('\n'.join(issues))
print(f'Public audit passed: {len(paths)-1} tracked files')
