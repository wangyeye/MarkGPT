#!/usr/bin/env python3
"""Fetch pinned preview assets and upstream licenses; build and use are offline."""
from pathlib import Path
import sys, shutil, urllib.request, tarfile, tempfile
if sys.version_info < (3,9): raise SystemExit('Python 3.9+ required')
root=Path(__file__).resolve().parents[1]/'Sources/MarkGPT/Web'
assets={
'marked.js':'https://cdn.jsdelivr.net/npm/marked@15.0.12/marked.min.js',
'mermaid.js':'https://cdn.jsdelivr.net/npm/mermaid@10.9.3/dist/mermaid.min.js',
'purify.js':'https://cdn.jsdelivr.net/npm/dompurify@3.2.6/dist/purify.min.js',
'highlight.js':'https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11.11.1/highlight.min.js',
'MARKED-LICENSE':'https://cdn.jsdelivr.net/npm/marked@15.0.12/LICENSE.md',
'MERMAID-LICENSE':'https://cdn.jsdelivr.net/npm/mermaid@10.9.3/LICENSE',
'DOMPURIFY-LICENSE':'https://cdn.jsdelivr.net/npm/dompurify@3.2.6/LICENSE',
'HIGHLIGHT-LICENSE':'https://cdn.jsdelivr.net/npm/@highlightjs/cdn-assets@11.11.1/LICENSE'}
root.mkdir(parents=True,exist_ok=True)
for name,url in assets.items():
    with urllib.request.urlopen(url,timeout=45) as r: (root/name).write_bytes(r.read())
with tempfile.TemporaryDirectory(prefix='markgpt-assets-') as tmp:
    archive=Path(tmp)/'katex.tgz'
    urllib.request.urlretrieve('https://registry.npmjs.org/katex/-/katex-0.16.22.tgz',archive)
    with tarfile.open(archive) as t: t.extractall(tmp,filter='data')
    dist=Path(tmp)/'package/dist'
    for source,target in [('katex.min.js','katex.js'),('katex.min.css','katex.css')]: shutil.copyfile(dist/source,root/target)
    shutil.copytree(dist/'fonts',root/'fonts',dirs_exist_ok=True)
    shutil.copyfile(Path(tmp)/'package/LICENSE',root/'KATEX-LICENSE')
print('Pinned assets and licenses fetched')
