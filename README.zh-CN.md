# MarkGPT

[English](README.md) | **简体中文**

原生 macOS Markdown 编辑与 AI 写作工作台。左侧工作区文件树及聊天列表，中间文档编辑／预览，右侧 AI 聊天。基于 TermGPT 的交互方向独立开发，不修改或共享 TermGPT 的数据。

![MarkGPT](Assets/AppIcon.png)

## 下载

从 [GitHub Releases](https://github.com/wangyeye/MarkGPT/releases) 下载 `MarkGPT-macOS-arm64.zip`（Apple Silicon）或 `MarkGPT-macOS-x86_64.zip`（Intel），解压并拖到 Applications。`SHA256SUMS` 用于校验。

需要 macOS 13+。安装包为 ad-hoc 签名，尚无 Developer ID 签名或公证。Intel 版本完成交叉编译与架构检查，未在实体 Intel Mac 实测。

## 功能与使用

- 三栏工作台；可显示／隐藏左右侧栏，支持专注模式和布局记忆。
- 多工作区磁盘目录树；点击文件打开，目录可移除或在 Finder 显示。浏览工作区不会自动发送整个目录给 AI。
- 多文档标签；新建、打开 `.md`／`.markdown`／UTF-8 文本、保存、另存为；未保存状态提醒，关闭时选择保存／取消／放弃。
- 原文、预览、分屏视图；行号、基础 Markdown 语法高亮、自动缩进、系统查找替换及原生撤销重做。
- 格式菜单可插入标题、强调、链接、图片、代码块、列表、任务、引用及表格模板。
- 草稿和标签保存在本机，重启可恢复。自动保存默认为关闭，可在设置开启；仅已命名文件自动保存。
- 保存前检查磁盘文件是否被其他程序改动；检测到差异时停止保存，使用另存为保留双方版本。
- 离线预览：表格、任务列表、代码高亮、相对路径本地图片、KaTeX 数学公式和 Mermaid 图表。预览清理原始 HTML，禁止文档脚本与远程图片自动请求；点击网页链接交给默认浏览器。
- PDF：顶部 PDF 或 Cmd+P，设置 A4／Letter、方向、页边距、字号、行距、页眉／页脚及页码后保存。采用浅色、矢量文字渲染；较长的表格／代码／图形可能在分页边界分割，导出后请检查排版。
- 独立多聊天，支持重命名、删除、Markdown 导出、流式回复、取消。聊天操作位于左侧每项右键菜单。
- 上下文支持关闭、自动、选区、当前章节、文档、手动参考文件与固定上下文。显示附带文档及字符数量；最多 48,000 字符，参考文件单项最多 16,000 字符。当前 Auto 使用文档上下文；明确不附带时选择关闭。
- “发送”用于普通聊天；“修改文档”要求 AI 返回完整修订 Markdown，默认展示红绿差异，点击应用后改动文档。
- 可开启自动应用，成功完整返回且原文未变时直接应用；每次 AI 修改都可用“撤销 AI 修改”恢复最近一次 AI 修改前的内容。该操作也会撤回之后的手工更改，请先保存需要保留的内容。
- 发出修改请求后手工改动原文、切换标签或关闭文档，AI 不会覆盖错误文档。冲突建议保留供查看，需重新生成后才能应用。
- 回复可复制、插入当前编辑器光标处或打开为新文档。选区右键可准备 AI 修改请求。
- 界面语言跟随系统／English／简体中文；主题跟随系统／浅色／深色。文档与聊天内容不会随界面语言自动翻译。

## 连接 AI

设置中 ChatGPT 为默认供应商，点击 **Continue with ChatGPT** 在浏览器完成登录及套餐授权。连接、模型及额度取决于服务端；Auto 选择可见模型目录中的默认项，不等同于 ChatGPT 网页路由。MarkGPT 不读取网页历史聊天。

也可选择 OpenAI API、Ollama、LM Studio 或兼容 Chat Completions 的接口，填写 Base URL、实际模型名及所需 API Key。本机默认地址分别为 `http://127.0.0.1:11434/v1` 和 `http://127.0.0.1:1234/v1`；远程接口要求 HTTPS。本地服务需自行启动。

ChatGPT 登录／流式连接组件来自 TermGPT 的 MIT 实现，使用官方 OAuth 与 Responses 服务。真实账户登录和推理需用户授权账户后验证；模拟测试不代表真实模型、套餐或网络已验证。

## 数据与隐私

设置、工作区路径、文档草稿和可选聊天保存在 `~/Library/Application Support/MarkGPT/workspace.json`；登录信息及 API Key 以明文 JSON 保存在同目录 `credentials.json`。目录权限 0700，文件 0600。数据独立于 TermGPT。损坏凭据文件不会被静默覆盖。

关闭“保存聊天”后，工作区配置不再写入聊天记录；草稿仍会保存。AI 调用按上下文设置发送文档内容；“修改文档”会附带完整当前文档，超过 48,000 字符时拒绝自动修改。发送前脱敏默认开启，仅匹配常见敏感字段，不能保证发现所有秘密。脱敏后的内容可能出现在 AI 修订文档中，应用前应查看差异。

源码、安装包和聊天导出不包含本机凭据；聊天导出进行常见字段脱敏。发布仅提交 MarkGPT 独立仓库中的源码与静态资源。

## 快捷键

| 快捷键 | 功能 |
|---|---|
| Cmd+N | 新建文档 |
| Cmd+O | 打开文档 |
| Cmd+S / Cmd+Shift+S | 保存／另存为 |
| Cmd+W | 关闭当前文档 |
| Cmd+F | 查找／替换 |
| Cmd+P | PDF 导出设置 |
| Cmd+Shift+N | 新建聊天 |
| Cmd+, | 设置 |
| Enter / Option+Enter | 发送聊天／换行；中文候选确认不发送 |
| Cmd+Z / Cmd+Shift+Z | 手工编辑撤销／重做 |

## 环境检查、构建及测试

需要 macOS 13+、Swift 5.9+、Xcode Command Line Tools、Python 3.9+ 和系统签名／打包工具。无需 Node、npm、Rust或完整 Xcode；预览依赖已固定并随源码提供。

```bash
./scripts/check-environment.sh
./scripts/test.sh
./scripts/test-with-fixture.sh
./scripts/build.sh
./scripts/verify-package.sh
./scripts/run.sh
```

构建默认使用 `/private/tmp/markgpt-release`，测试使用 `/private/tmp/markgpt-build`，避免同步目录的签名元数据。用 `MARKGPT_BUILD_DIR` 可覆盖构建缓存路径。发行文件输出到项目 `dist/`。

## 脚本说明

所有处理脚本保存在项目 `scripts/` 内，并在使用前检查环境。

| 脚本 | 功能、作用及使用 |
|---|---|
| `check-environment.sh` | 检查 macOS、Swift、SDK、Python和系统工具；失败时退出 |
| `toolchain.sh` | 供其他脚本引用，定位工作区缓存及可选工具链资源 |
| `build.sh` | 编译 ARM／Intel、生成图标、打包并写校验和 |
| `package-app.sh <binary> <arch>` | 构建脚本调用；组装 App、复制预览资源、签名并生成 ZIP |
| `make-icon.sh` | 检查 sips/iconutil，调用图标源脚本生成 PNG／ICNS |
| `make-icon.swift <output.png>` | AppKit 绘制图标；由 make-icon.sh 调用 |
| `run.sh` | 检查环境，缺少发行 App 时先构建，再打开 App |
| `test.sh` | 构建并运行合成数据自检，无真实账户调用 |
| `render-test.sh` | 打开测试窗口，检查真实渲染、图片及 PDF，需要图形登录会话 |
| `test-with-fixture.sh` | 隔离数据目录，启动本机模拟 API，测试审阅、应用、冲突及聊天；退出清理服务 |
| `mock-provider.py <port-file>` | 固定 SSE 模拟服务，仅绑定 127.0.0.1；由 fixture 脚本调用 |
| `fetch-web-assets.py` | 维护者更新固定版本渲染依赖及许可证，需要网络；正常构建不用运行 |
| `verify-package.sh` | 独立解压双架构 ZIP，验证签名、资源、ARM 自检和校验和 |
| `audit-public.py` | 检查 Git 跟踪文件中禁止配置、个人路径和典型凭据模式；发布前运行 |

测试数据通过 `MARKGPT_DATA_DIR` 隔离，不修改日常数据。真实服务验证不在无凭据测试中执行。

## 范围与许可证

MIT License，保留 TermGPT 原始组件版权。第三方渲染依赖版本和许可证见 [THIRD_PARTY.md](THIRD_PARTY.md)。MarkGPT 不是 OpenAI 官方产品。

首版不包含跨文件自主修改、云同步、多人协作、所见即所得编辑、插件或 Word 导出。Markdown 链接图片支持本地相对文件；远程图片需下载到工作区后引用。
