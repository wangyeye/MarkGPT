# MarkGPT v0.1.0

Native macOS Markdown and AI writing workbench, developed independently from TermGPT.

## Features / 功能

- Workspace file tree and chat list, document editor/preview, AI conversation.
- Source/preview/split views, multi-document tabs, draft recovery, optional auto-save and external change protection.
- AI edit review with highlighted differences, automatic application, AI undo and concurrent edit conflict protection.
- Offline tables, local images, math, Mermaid and syntax-highlighted code.
- PDF export: A4/Letter, orientation, margins, font/line spacing, headers, footers and page numbers.
- ChatGPT connection and OpenAI-compatible/local providers; English and Simplified Chinese UI and documentation.
- Fixed the WebKit asynchronous-return alert during startup and editing.

## Downloads / 下载

- Apple Silicon: `MarkGPT-macOS-arm64.zip`
- Intel: `MarkGPT-macOS-x86_64.zip`
- Checksums: `SHA256SUMS`

Extract and move MarkGPT.app to Applications. Requires macOS 13+. Ad-hoc signed; not Developer ID signed or notarized.

解压并将 MarkGPT.app 拖到 Applications。需要 macOS 13+；当前采用 ad-hoc 签名，尚无 Developer ID 签名或公证。

## Validation / 验证

Apple Silicon startup and manual editing verified. Synthetic tests cover credential persistence/permissions, draft encoding, edit extraction, target/version checks and OAuth PKCE. Real WebKit tests cover Chinese, tables, math, diagrams, code highlighting, script sanitization, relative images and PDF output. Loopback SSE integration covers chat, review/apply, AI undo, automatic application and concurrent manual changes. Both archives pass independent extraction, architecture, signing, resource and checksum checks.

Intel hardware and live authenticated AI inference have not been tested. Long blocks can split at PDF page boundaries; inspect exported layout.

已验证 Apple Silicon 启动及手工编辑、真实预览与 PDF、本机模拟 AI 编辑流程和双架构安装包。实体 Intel Mac 与真实账户推理未实测。长表格／代码／图表可能跨页分割，请检查导出排版。
