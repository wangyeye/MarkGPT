# Third-party components

Preview runs offline from pinned assets in `Sources/MarkGPT/Web`. The source download script is `scripts/fetch-web-assets.py`.

| Component | Version | License | Upstream |
|---|---|---|---|
| marked | 15.0.12 | MIT, Web/MARKED-LICENSE | https://github.com/markedjs/marked |
| DOMPurify | 3.2.6 | Apache-2.0 OR MPL-2.0, Web/DOMPURIFY-LICENSE | https://github.com/cure53/DOMPurify |
| Mermaid | 10.9.3 | MIT, Web/MERMAID-LICENSE | https://github.com/mermaid-js/mermaid |
| KaTeX and fonts | 0.16.22 | MIT, Web/KATEX-LICENSE | https://github.com/KaTeX/KaTeX |
| highlight.js | 11.11.1 | BSD-3-Clause, Web/HIGHLIGHT-LICENSE | https://github.com/highlightjs/highlight.js |

OAuth, provider streaming, localization foundation, credential storage and chat input derive from the MIT-licensed TermGPT project: https://github.com/wangyeye/TermGPT. Original copyright is retained in LICENSE. MarkGPT does not include SwiftTerm or SSH components.

The application icon is drawn from project-owned AppKit geometry in scripts/make-icon.swift.
