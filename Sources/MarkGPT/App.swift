import AppKit
import SwiftUI

@main struct MarkGPTApp: App {
  init() {
    if CommandLine.arguments.contains("--self-test") {
      do {
        try SelfTests.run()
        exit(0)
      } catch {
        fputs("Self-test failed: \(error)\n", stderr)
        exit(1)
      }
    }
  }
  @StateObject var workspace = Workspace()
  var body: some Scene {
    WindowGroup { MainView(w: workspace).frame(minWidth: 1100, minHeight: 650) }.defaultSize(
      width: 1400, height: 850
    )
    .commands {
      CommandGroup(replacing: .newItem) {
        Button(T("新建文档", "New Document")) { workspace.newDocument() }.keyboardShortcut("n")
        Button(T("打开…", "Open…")) { workspace.open() }.keyboardShortcut("o")
        Button(T("新建聊天", "New Chat")) { workspace.newChat() }.keyboardShortcut(
          "n", modifiers: [.command, .shift])
      }
      CommandGroup(replacing: .saveItem) {
        Button(T("保存", "Save")) { workspace.save() }.keyboardShortcut("s")
        Button(T("另存为…", "Save As…")) { workspace.save(asNew: true) }.keyboardShortcut(
          "s", modifiers: [.command, .shift])
        Button(T("导出 PDF…", "Export PDF…")) { workspace.pdfSettings = true }.keyboardShortcut("p")
      }
      CommandGroup(replacing: .appSettings) {
        Button(T("设置…", "Settings…")) { workspace.settings = true }.keyboardShortcut(",")
      }
      CommandMenu(T("文档", "Document")) {
        Button(T("关闭文档", "Close Document")) { if let id = workspace.active { workspace.close(id) } }
          .keyboardShortcut("w")
        Button(T("查找与替换", "Find and Replace")) {
          let item = NSMenuItem()
          item.tag = 1
          workspace.editor?.performFindPanelAction(item)
        }.keyboardShortcut("f")
      }
    }
  }
}
struct MainView: View {
  @ObservedObject var w: Workspace
  @ObservedObject var locale = Localization.shared
  @State var preview = PreviewController()
  @State var rename: UUID?
  @State var title = ""
  var body: some View {
    VStack(spacing: 0) {
      HSplitView {
        if w.preferences.showBookmarks {
          sidebar.frame(minWidth: 180, idealWidth: 220, maxWidth: 260)
        }
        center.frame(minWidth: 550, idealWidth: 800)
        if w.preferences.showChat { chat.frame(minWidth: 320, idealWidth: 360, maxWidth: 520) }
      }
      Divider()
      HStack {
        Text(w.document?.path ?? T("未保存文档", "Unsaved document")).lineLimit(1)
        Spacer()
        Text("\(w.document?.text.count ?? 0) " + T("字符", "characters"))
        Text(w.busy ? T("AI 正在回复", "AI responding") : w.preferences.provider.rawValue)
      }.font(.caption).padding(8)
    }.preferredColorScheme(
      w.preferences.interfaceTheme == .system
        ? nil : w.preferences.interfaceTheme == .dark ? .dark : .light
    )
    .toolbar {
      ToolbarItemGroup {
        Button {
          w.newDocument()
        } label: {
          Image(systemName: "doc.badge.plus")
        }
        Button {
          w.open()
        } label: {
          Image(systemName: "folder")
        }
        Button {
          w.save()
        } label: {
          Image(systemName: "square.and.arrow.down")
        }
        Button {
          w.preferences.showBookmarks.toggle()
          w.persist()
        } label: {
          Image(systemName: "sidebar.left")
        }
        Button {
          w.preferences.showChat.toggle()
          w.persist()
        } label: {
          Image(systemName: "sidebar.right")
        }
        Button {
          w.preferences.showBookmarks = false
          w.preferences.showChat = false
          w.persist()
        } label: {
          Image(systemName: "rectangle")
        }
        Button {
          w.pdfSettings = true
        } label: {
          Label("PDF", systemImage: "printer")
        }
      }
    }
    .sheet(isPresented: $w.pdfSettings) { PDFSettingsView(controller: preview) }.sheet(
      isPresented: $w.settings
    ) { SettingsView(w: w) }.sheet(item: $w.proposal) { p in ProposalView(w: w, p: p) }
    .alert(
      "MarkGPT", isPresented: Binding(get: { w.error != nil }, set: { if !$0 { w.error = nil } })
    ) {
      Button(T("好", "OK")) { w.error = nil }
    } message: {
      Text(w.error ?? "")
    }
    .alert(
      T("重命名聊天", "Rename Chat"),
      isPresented: Binding(get: { rename != nil }, set: { if !$0 { rename = nil } })
    ) {
      TextField(T("名称", "Name"), text: $title)
      Button(T("保存", "Save")) {
        if let id = rename {
          _ = ChatActions.rename(id, title: title, chats: &w.chats)
          w.persist()
        }
        rename = nil
      }
      Button(T("取消", "Cancel")) { rename = nil }
    }
    .onAppear {
      w.preview = preview
      preview.issue = { w.error = $0 }
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)
      if CommandLine.arguments.contains("--render-test") { Task { await RenderTests.run(preview) } }
    }.onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification))
    { _ in
      w.task?.cancel()
      w.chatGPT.cancelLogin()
      w.persist()
    }.onOpenURL { w.open($0) }
  }
  var sidebar: some View {
    VSplitView {
      VStack(alignment: .leading) {
        HStack {
          Text("MarkGPT").font(.title2.bold())
          Spacer()
          Button {
            w.addRoot()
          } label: {
            Image(systemName: "folder.badge.plus")
          }
        }
        Text(T("工作区", "Workspaces")).font(.headline)
        ScrollView {
          ForEach(w.roots, id: \.self) { root in
            DisclosureGroup(URL(fileURLWithPath: root).lastPathComponent) {
              OutlineGroup(
                FileNode(url: URL(fileURLWithPath: root)).children ?? [], children: \.children
              ) { node in
                Button {
                  if !node.folder { w.open(node.url) }
                } label: {
                  Label(
                    node.url.lastPathComponent, systemImage: node.folder ? "folder" : "doc.text")
                }.buttonStyle(.plain)
              }
            }.contextMenu {
              Button(T("在 Finder 中显示", "Reveal in Finder")) {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: root)
              }
              Button(T("移除工作区", "Remove Workspace")) {
                w.roots.removeAll { $0 == root }
                w.persist()
              }
            }
          }
        }
      }.padding().frame(minHeight: 220)
      VStack(alignment: .leading) {
        HStack {
          Text(T("聊天", "Chats")).font(.headline)
          Spacer()
          Button {
            w.newChat()
          } label: {
            Image(systemName: "plus")
          }
        }
        ScrollView {
          ForEach(w.chats) { c in
            Button {
              w.chatID = c.id
            } label: {
              Text(c.name == "新聊天" ? T("新聊天", "New Chat") : c.name).frame(
                maxWidth: .infinity, alignment: .leading
              ).padding(7).background(w.chatID == c.id ? Color.accentColor.opacity(0.15) : .clear)
            }.buttonStyle(.plain).contextMenu {
              Button(T("重命名", "Rename")) {
                rename = c.id
                title = c.name
              }
              Button(T("删除", "Delete")) {
                _ = ChatActions.delete(c.id, chats: &w.chats, selected: &w.chatID)
                w.persist()
              }
            }
          }
        }
        Button(T("导出聊天", "Export Chat")) { w.exportChat() }
        Button(T("设置", "Settings")) { w.settings = true }
      }.padding().frame(minHeight: 180)
    }.background(Color(nsColor: .controlBackgroundColor))
  }
  var center: some View {
    VStack(spacing: 0) {
      ScrollView(.horizontal) {
        HStack {
          ForEach(w.documents) { d in
            HStack {
              Button {
                w.active = d.id
                w.selection = NSRange(location: 0, length: 0)
              } label: {
                Text(d.name + (d.dirty ? " ●" : ""))
              }
              Button {
                w.close(d.id)
              } label: {
                Image(systemName: "xmark").font(.caption)
              }
            }.buttonStyle(.plain).padding(9).background(
              w.active == d.id ? Color.accentColor.opacity(0.15) : .clear)
          }
        }
      }
      HStack {
        Picker(T("视图", "View"), selection: $w.mode) {
          Text(T("源码", "Source")).tag("source")
          Text(T("预览", "Preview")).tag("preview")
          Text(T("分屏", "Split")).tag("split")
        }.pickerStyle(.segmented).labelsHidden()
        Button(T("撤销 AI 修改", "Undo AI Edit")) { w.undoAI() }
        Menu(T("格式", "Format")) {
          ForEach(
            [
              "# ", "**text**", "*text*", "[text](https://)", "![image](image.png)", "```\n\n```",
              "- ", "- [ ] ", "> ", "| A | B |\n|---|---|\n| | |",
            ], id: \.self
          ) { s in Button(s) { w.insert(s) } }
        }
      }.padding(8)
      Divider()
      HSplitView {
        if w.mode != "preview" { EditorHost(workspace: w) }
        if w.mode != "source" {
          PreviewHost(controller: preview, text: w.document?.text ?? "", path: w.document?.path)
        }
      }
    }
  }
  var chat: some View {
    VStack(alignment: .leading) {
      HStack {
        Label(T("AI 聊天", "AI Chat"), systemImage: "sparkles")
        Spacer()
        if w.busy { Button(T("停止", "Stop")) { w.task?.cancel() } }
      }
      Picker(T("上下文", "Context"), selection: $w.contextMode) {
        Text(T("自动", "Auto")).tag("auto")
        Text(T("关闭", "Off")).tag("off")
        Text(T("选区", "Selection")).tag("selection")
        Text(T("章节", "Chapter")).tag("chapter")
        Text(T("文档", "Document")).tag("document")
      }
      HStack {
        Button(T("参考文档", "References")) { w.addReference() }
        Button(w.fixedContext == nil ? T("固定上下文", "Pin Context") : T("取消固定", "Unpin")) {
          if w.fixedContext == nil { w.fixedContext = w.context() } else { w.fixedContext = nil }
        }
      }
      Text(
        w.contextMode == "off"
          ? T("不附带文档", "No document attached")
          : (w.document?.name ?? "") + " · \(w.context().count) " + T("字符", "characters")
      ).font(.caption).foregroundStyle(.secondary)
      if !w.references.isEmpty {
        Menu("\(w.references.count) " + T("参考文档", "references")) {
          ForEach(w.references, id: \.self) { p in
            Button(URL(fileURLWithPath: p).lastPathComponent + " ×") {
              w.references.removeAll { $0 == p }
            }
          }
        }
      }
      Divider()
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 18) {
            ForEach(w.currentChat.messages) { m in
              VStack(alignment: .leading) {
                Text(m.role == "user" ? T("你", "You") : "AI").font(.caption.bold())
                Text(m.content).textSelection(.enabled)
                if m.role == "assistant", !w.busy {
                  HStack {
                    Button(T("复制", "Copy")) {
                      NSPasteboard.general.clearContents()
                      NSPasteboard.general.setString(m.content, forType: .string)
                    }
                    Button(T("插入", "Insert")) { w.insert(m.content) }
                    Button(T("新文档", "New Document")) {
                      w.newDocument((try? EditSafety.replacement(m.content)) ?? m.content)
                    }
                  }.font(.caption)
                }
              }
            }
            Color.clear.frame(height: 1).id("bottom")
          }
        }.onChange(of: w.currentChat.messages.last?.content) { _ in
          proxy.scrollTo("bottom", anchor: .bottom)
        }
      }
      Toggle(T("自动应用 AI 修改", "Automatically Apply AI Edits"), isOn: $w.autoApply).onChange(
        of: w.autoApply
      ) { _ in w.persist() }
      ChatInput(text: $w.input, onSubmit: { w.send() }).frame(height: 100)
      HStack {
        Button(T("发送", "Send")) { w.send() }
        Button(T("修改文档", "Edit Document")) { w.send(edit: true) }.buttonStyle(.borderedProminent)
      }.disabled(w.busy || w.input.isEmpty)
    }.padding(14)
  }
}
struct ProposalView: View {
  @ObservedObject var w: Workspace
  let p: EditProposal
  var body: some View {
    VStack {
      Text(T("审阅 AI 修改", "Review AI Edit")).font(.title2)
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(LineDiff.rows(old: p.original, new: p.replacement)) { r in
            Text(r.text).font(.system(size: 12, design: .monospaced)).frame(
              maxWidth: .infinity, alignment: .leading
            ).padding(.vertical, 2).background(
              r.kind == 1
                ? Color.green.opacity(0.15) : r.kind == -1 ? Color.red.opacity(0.15) : .clear
            ).textSelection(.enabled)
          }
        }
      }
      Text(
        T(
          "绿色新增，红色删除。文档改变时无法应用。",
          "Green additions, red deletions. Application requires an unchanged document.")
      ).font(.caption)
      HStack {
        Button(T("拒绝", "Reject")) { w.proposal = nil }
        Spacer()
        Button(T("应用", "Apply")) { w.apply(p) }.buttonStyle(.borderedProminent)
      }
    }.padding(20).frame(width: 900, height: 620)
  }
}
struct SettingsView: View {
  @ObservedObject var w: Workspace
  @Environment(\.dismiss) var dismiss
  @State var key = ""
  var body: some View {
    VStack {
      Text(T("设置", "Settings")).font(.title2)
      Form {
        Picker(T("界面语言", "Interface Language"), selection: $w.preferences.language) {
          ForEach(InterfaceLanguage.allCases, id: \.self) { Text($0.label).tag($0) }
        }
        Picker(T("主题", "Theme"), selection: $w.preferences.interfaceTheme) {
          ForEach(InterfaceTheme.allCases, id: \.self) { Text(L($0.rawValue)).tag($0) }
        }
        Picker("AI Provider", selection: $w.preferences.provider) {
          ForEach(ProviderKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }.onChange(of: w.preferences.provider) { p in
          if p != .chatGPT { w.preferences.endpoint = p.defaultEndpoint }
        }
        if w.preferences.provider == .chatGPT {
          AccountSettings(account: w.chatGPT, preferences: $w.preferences)
        } else {
          TextField("API Base URL", text: $w.preferences.endpoint)
          TextField(T("模型", "Model"), text: $w.preferences.model)
          SecureField("API Key", text: $key)
        }
        Slider(value: $w.preferences.fontSize, in: 10...24, step: 1) {
          Text(T("字体大小", "Font Size"))
        }
        Toggle(T("自动保存文档", "Automatically Save Documents"), isOn: $w.autoSave)
        Toggle(T("保存聊天", "Save Chat History"), isOn: $w.preferences.saveMemory)
        Toggle(T("发送前脱敏", "Redact Before Sending"), isOn: $w.preferences.redactBeforeSending)
        Text(
          T(
            "登录信息和密钥保存在本机权限受限的 JSON 中。",
            "Credentials are stored in a permission-restricted local JSON file.")
        ).font(.caption)
      }
      Button(T("保存并关闭", "Save and Close")) {
        do {
          try APIKeyStore.write(key)
          w.persist()
          dismiss()
        } catch { w.error = error.localizedDescription }
      }
    }.padding(24).frame(width: 620).onAppear {
      do { key = try APIKeyStore.read() } catch { w.error = error.localizedDescription }
    }
  }
}
struct AccountSettings: View {
  @ObservedObject var account: ChatGPTAccount
  @Binding var preferences: Preferences
  var body: some View {
    VStack(alignment: .leading) {
      if account.connected {
        Text(account.account?.email ?? "ChatGPT")
        Text(account.account?.plan ?? T("套餐名称未返回", "Plan name unavailable"))
        Picker(T("模型", "Model"), selection: $preferences.chatGPTModel) {
          Text("Auto").tag("")
          ForEach(account.models) { Text($0.name).tag($0.id) }
        }
        Button(T("刷新模型", "Refresh Models")) { Task { await account.refreshModels() } }
        Button(T("断开连接", "Disconnect")) { Task { await account.disconnect() } }
      } else {
        Button("Continue with ChatGPT") { account.connect() }.disabled(
          account.connecting || account.loadingAccount)
        if account.connecting { Button(T("取消登录", "Cancel Login")) { account.cancelLogin() } }
      }
      Text(L(account.message)).font(.caption)
    }.task { if account.connected { await account.refreshModels() } }.alert(
      T("使用 ChatGPT 套餐", "Using ChatGPT Plan"), isPresented: $account.welcome
    ) {
      Button(T("知道了", "Got it")) { account.acknowledgeWelcome() }
    } message: {
      Text(T("合资格请求使用你授权的套餐或额度。", "Eligible requests use your authorized plan or quota."))
    }
  }
}
