# MarkGPT

**English** | [简体中文](README.zh-CN.md)

A native macOS Markdown and AI writing workbench: workspace folders and chats on the left, document editing and preview in the center, AI conversation on the right. Developed independently from TermGPT with separate application data.

![MarkGPT](Assets/AppIcon.png)

## Download

[GitHub Releases](https://github.com/wangyeye/MarkGPT/releases) provides `MarkGPT-macOS-arm64.zip` for Apple Silicon and `MarkGPT-macOS-x86_64.zip` for Intel, plus `SHA256SUMS`. Extract and move MarkGPT.app to Applications. Requires macOS 13+.

Packages use ad-hoc signing, without Developer ID signing or notarization. Intel is cross-compiled and architecture-checked; physical Intel hardware has not been tested.

## Features and usage

- Three-pane layout, adjustable panes, sidebar visibility, focus mode and saved layout.
- Multiple local workspace folders and expandable disk trees. Click files to open; remove roots or reveal them in Finder. Browsing does not send directory contents to AI.
- Multiple document tabs; open Markdown/UTF-8 text, create, save, Save As, unsaved indicators and close prompts.
- Source, preview and split views; line numbers, basic syntax highlighting, automatic indentation, native find/replace and manual undo/redo.
- Formatting templates for headings, emphasis, links, images, code, lists, tasks, quotes and tables.
- Draft recovery across launches. Optional automatic saving for named documents, disabled by default. Detects external file changes before writing and refuses to overwrite conflicting disk content.
- Offline preview with tables, tasks, code highlighting, local relative images, KaTeX math and Mermaid diagrams. Sanitizes HTML, disables document scripts and automatic remote image requests. Web links open in the default browser.
- PDF export with A4/Letter, orientation, margins, font size, line height, headers, footers and page numbers. Light output with vector text. Long tables, code and diagrams can split at page boundaries; inspect exported layout.
- Multiple chats with rename/delete context menus, Markdown export, streaming and cancellation.
- Context modes: Off, Auto, Selection, Chapter and Document; manual reference documents and pinned context. Displays attachment and character count; limited to 48,000 characters overall and 16,000 per reference. Auto currently attaches document context; choose Off for explicit exclusion.
- Send for conversation; Edit Document requests a complete revised Markdown document. Review highlighted additions/deletions before applying, or enable automatic application.
- Edits are bound to the captured document and its original content. Concurrent manual changes prevent automatic application, and closed documents cannot be overwritten.
- Undo AI Edit restores the content before the most recent AI edit. This also removes subsequent manual changes; save anything you want to retain first.
- Copy, insert at the cursor or create a new document from replies. The editor context menu prepares a selected-text editing prompt.
- System/English/Simplified Chinese interface and System/Light/Dark themes. Document and chat content is not automatically translated.

## AI connection

ChatGPT is the default provider. Use Continue with ChatGPT in Settings to authorize your account and plan in your browser. Eligibility, models and quota are controlled by the service. Auto selects an available model; it does not reproduce ChatGPT web routing. MarkGPT does not read ChatGPT web history.

OpenAI API, Ollama, LM Studio and OpenAI-compatible Chat Completions providers are also available. Configure Base URL, actual model ID and any required API key. Ollama defaults to `http://127.0.0.1:11434/v1`; LM Studio to `http://127.0.0.1:1234/v1`. Start local servers separately. Remote endpoints require HTTPS.

The MIT-licensed ChatGPT connection component derives from TermGPT and uses official OAuth/Responses services. Real account login and inference require an authorized user account; fixture tests do not establish live account, plan or model availability.

## Storage and privacy

Settings, workspace paths, document drafts and optional chats are stored in `~/Library/Application Support/MarkGPT/workspace.json`. Login credentials and API keys are stored as plaintext JSON in `credentials.json`, with directory mode 0700 and file mode 0600. MarkGPT data is independent of TermGPT. Malformed credential files are preserved.

Disabling Save Chat History excludes conversations from saved workspace state; drafts are still saved. Edit Document sends the entire current document, even when a selected scope is used, and rejects documents exceeding 48,000 characters. Redaction defaults to on and matches common secret formats only. Redacted text may appear in AI revisions; review changes before applying them.

Source and release packages exclude credentials and user state. Chat export redacts common secret patterns.

## Shortcuts

| Shortcut | Action |
|---|---|
| Cmd+N / Cmd+O | New / Open document |
| Cmd+S / Cmd+Shift+S | Save / Save As |
| Cmd+W | Close current document |
| Cmd+F | Find / Replace |
| Cmd+P | PDF settings |
| Cmd+Shift+N | New chat |
| Cmd+, | Settings |
| Enter / Option+Enter | Send / newline; IME candidate confirmation does not send |
| Cmd+Z / Cmd+Shift+Z | Manual editing undo / redo |

## Build and verify

Requires macOS 13+, Swift 5.9+, Xcode Command Line Tools, Python 3.9+ and standard macOS packaging tools. No Node, npm, Rust or full Xcode requirement. Pinned preview dependencies are bundled.

```bash
./scripts/check-environment.sh
./scripts/test.sh
./scripts/test-with-fixture.sh
./scripts/build.sh
./scripts/verify-package.sh
./scripts/run.sh
```

Release artifacts appear in `dist/`. Temporary build paths avoid sync-folder signing metadata: `/private/tmp/markgpt-release` and `/private/tmp/markgpt-build`. Override with `MARKGPT_BUILD_DIR` if needed.

## Scripts

All processing scripts live in `scripts/` and check requirements before use.

| Script | Purpose and usage |
|---|---|
| `check-environment.sh` | Validate OS, Swift, SDK, Python and system tools |
| `toolchain.sh` | Sourced by build/test scripts to configure caches and optional tools |
| `build.sh` | Build ARM/Intel apps, icons, ZIPs and checksums |
| `package-app.sh <binary> <arch>` | Assemble resources, sign and archive an executable |
| `make-icon.sh` | Check sips/iconutil and generate PNG/ICNS from icon source |
| `make-icon.swift <output.png>` | Draw the AppKit icon; invoked by make-icon.sh |
| `run.sh` | Check environment, build if needed and launch |
| `test.sh` | Compile and run synthetic self-tests without real credentials |
| `render-test.sh` | Launch UI tests for WebKit rendering, images and PDF; needs a graphical session |
| `test-with-fixture.sh` | Isolate data, start loopback SSE fixture, verify chat/edit workflows and clean up |
| `mock-provider.py <port-file>` | Loopback-only synthetic provider used by fixture tests |
| `fetch-web-assets.py` | Maintainer-only pinned dependency/license download; needs network, not required for builds |
| `verify-package.sh` | Extract ZIPs independently, verify architectures, signing, resources, ARM checks and checksums |
| `audit-public.py` | Audit Git-tracked source for user state, personal paths and common credential patterns |

Test data uses isolated `MARKGPT_DATA_DIR`; real account verification is separate.

## License and scope

MIT License; original TermGPT component copyrights retained. See [THIRD_PARTY.md](THIRD_PARTY.md) for pinned rendering dependencies and licenses. This is not an official OpenAI product.

No cross-file autonomous editing, cloud sync, collaboration, rich WYSIWYG mode, plugin system or Word export in this release. Download remote images into a workspace before referencing them.
