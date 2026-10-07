import AppKit
import PDFKit
import SwiftUI
import WebKit

struct EditorHost: NSViewRepresentable {
  @ObservedObject var workspace: Workspace
  func makeCoordinator() -> Coordinator { Coordinator(workspace) }
  func makeNSView(context: Context) -> NSScrollView {
    let scroll = NSScrollView()
    scroll.hasVerticalScroller = true
    let view = MarkdownTextView()
    view.isRichText = false
    view.allowsUndo = true
    view.isAutomaticQuoteSubstitutionEnabled = false
    view.isAutomaticDashSubstitutionEnabled = false
    view.isAutomaticSpellingCorrectionEnabled = false
    view.isIncrementalSearchingEnabled = true
    view.usesFindBar = true
    view.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
    view.autoresizingMask = [.width]
    view.textContainer?.widthTracksTextView = true
    view.isVerticallyResizable = true
    view.textContainerInset = NSSize(width: 16, height: 16)
    view.delegate = context.coordinator
    scroll.documentView = view
    let ruler = LineRuler(scrollView: scroll, orientation: .verticalRuler)
    ruler.clientView = view
    ruler.ruleThickness = 42
    scroll.verticalRulerView = ruler
    scroll.hasVerticalRuler = true
    scroll.rulersVisible = true
    view.ask = {
      workspace.contextMode = "selection"
      workspace.input = T("请修改选中的文本：", "Please edit the selected text: ")
    }
    workspace.editor = view
    return scroll
  }
  func updateNSView(_ scroll: NSScrollView, context: Context) {
    guard let v = scroll.documentView as? NSTextView else { return }
    let text = workspace.document?.text ?? ""
    if v.string != text || context.coordinator.id != workspace.active {
      v.string = text
      v.undoManager?.removeAllActions()
      context.coordinator.id = workspace.active
    }
    v.font = .monospacedSystemFont(ofSize: workspace.preferences.fontSize, weight: .regular)
    v.textColor = .textColor
    v.backgroundColor = .textBackgroundColor
    workspace.editor = v
    context.coordinator.highlight(v)
  }
  final class Coordinator: NSObject, NSTextViewDelegate {
    let w: Workspace
    var id: UUID?
    init(_ w: Workspace) { self.w = w }
    func textDidChange(_ n: Notification) {
      guard let v = n.object as? NSTextView else { return }
      w.changed(v.string)
      highlight(v)
      v.enclosingScrollView?.verticalRulerView?.needsDisplay = true
    }
    func textViewDidChangeSelection(_ n: Notification) {
      if let v = n.object as? NSTextView { w.selection = v.selectedRange() }
    }
    func highlight(_ v: NSTextView) {
      guard let s = v.textStorage else { return }
      let r = NSRange(location: 0, length: s.length)
      s.addAttribute(.foregroundColor, value: NSColor.textColor, range: r)
      for pattern in ["(?m)^#{1,6} .*?$", "\\*\\*[^*]+\\*\\*", "`[^`]+`", "(?m)^>.*$"] {
        if let regex = try? NSRegularExpression(pattern: pattern) {
          for m in regex.matches(in: v.string, range: r) {
            s.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: m.range)
          }
        }
      }
    }
  }
}
@MainActor final class PreviewController: NSObject, WKNavigationDelegate {
  let web: WKWebView
  var loaded = false
  var pending = ""
  var root: URL?
  var issue: ((String) -> Void)?
  override init() {
    let c = WKWebViewConfiguration()
    web = WKWebView(frame: .zero, configuration: c)
    super.init()
    web.navigationDelegate = self
  }
  func update(text: String, path: String?) {
    pending = text
    let folder = path.map { URL(fileURLWithPath: $0).deletingLastPathComponent() }
    if !loaded || folder != root {
      root = folder
      load()
    } else {
      render()
    }
  }
  func load() {
    loaded = false
    guard let assets = Bundle.module.url(forResource: "Web", withExtension: nil) else { return }
    let base = assets
    let html = """
      <!doctype html><html><head><meta charset="utf-8"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src file: 'unsafe-inline' 'unsafe-eval'; style-src file: 'unsafe-inline'; img-src file: data:; font-src file: data:; connect-src 'none';"><link rel="stylesheet" href="\(assets.appendingPathComponent("katex.css").absoluteString)"><style>body{font:16px -apple-system,BlinkMacSystemFont,'PingFang SC',sans-serif;line-height:1.65;color:#20252c;background:white;max-width:880px;margin:28px auto;padding:0 24px}pre{white-space:pre-wrap;background:#f2f4f6;padding:14px;border-radius:6px}code{font-family:monospace}img,svg{max-width:100%;height:auto}table{border-collapse:collapse;max-width:100%}td,th{border:1px solid #ccc;padding:6px}blockquote{border-left:3px solid #aaa;padding-left:16px;color:#666}.hljs-keyword,.hljs-title{color:#185abd}.hljs-string{color:#257743}@media print{body{margin:0;max-width:none}pre,tr,img,svg{break-inside:avoid}}</style></head><body><main id="content"></main><script src="\(assets.appendingPathComponent("marked.js").absoluteString)"></script><script src="\(assets.appendingPathComponent("purify.js").absoluteString)"></script><script src="\(assets.appendingPathComponent("highlight.js").absoluteString)"></script><script src="\(assets.appendingPathComponent("katex.js").absoluteString)"></script><script src="\(assets.appendingPathComponent("mermaid.js").absoluteString)"></script><script>
      mermaid.initialize({startOnLoad:false,securityLevel:'strict'});let revision=0;window.render=async function(text){const rev=++revision;const math=[];text=text.replace(/\\$\\$([\\s\\S]+?)\\$\\$|\\$([^\\n$]+)\\$/g,(m,a,b)=>{math.push(katex.renderToString(a||b,{displayMode:!!a,throwOnError:false}));return 'MARKGPTMATH'+(math.length-1)+'TOKEN'});let html=marked.parse(text);html=html.replace(/MARKGPTMATH(\\d+)TOKEN/g,(m,n)=>math[Number(n)]);document.getElementById('content').innerHTML=DOMPurify.sanitize(html,{ADD_TAGS:['annotation','semantics'],ADD_ATTR:['encoding']});for(const code of document.querySelectorAll('pre code')){if(code.classList.contains('language-mermaid')){const node=document.createElement('div');node.className='mermaid';node.textContent=code.textContent;code.parentNode.replaceWith(node)}else{hljs.highlightElement(code)}}try{await mermaid.run({querySelector:'.mermaid'})}catch(e){}await document.fonts.ready;await Promise.all([...document.images].map(i=>i.complete?Promise.resolve():new Promise(r=>{i.onload=r;i.onerror=r})));if(rev===revision)window.ready=true;};
      </script></body></html>
      """
    web.loadHTMLString(html, baseURL: base)
  }
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    loaded = true
    render()
  }
  func inlineImages(_ text: String) -> String {
    guard let root, let regex = try? NSRegularExpression(pattern: #"!\[([^\]]*)\]\(([^)]+)\)"#)
    else { return text }
    var result = text
    let ns = text as NSString
    for m in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
      let original = ns.substring(with: m.range(at: 2))
      let href = original.components(separatedBy: " \"").first!.trimmingCharacters(
        in: CharacterSet(charactersIn: "<>"))
      guard !href.contains(":") else { continue }
      let candidate = root.appendingPathComponent(href.removingPercentEncoding ?? href)
        .standardizedFileURL.resolvingSymlinksInPath()
      let allowed = root.resolvingSymlinksInPath().path + "/"
      guard candidate.path.hasPrefix(allowed) else { continue }
      let types = [
        "png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "gif": "image/gif",
        "webp": "image/webp", "svg": "image/svg+xml",
      ]
      guard let mime = types[candidate.pathExtension.lowercased()],
        let data = try? Data(contentsOf: candidate), data.count <= 20_000_000
      else { continue }
      let range = Range(m.range(at: 2), in: result)!
      result.replaceSubrange(range, with: "data:" + mime + ";base64," + data.base64EncodedString())
    }
    return result
  }
  func render() {
    guard let data = try? JSONSerialization.data(withJSONObject: [inlineImages(pending)]),
      let json = String(data: data, encoding: .utf8)
    else { return }
    web.evaluateJavaScript(
      "window.ready=false;window.render(\(json)[0]);null;",
      completionHandler: { _, error in if let error { self.issue?(error.localizedDescription) } })
  }
  func webView(
    _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    if navigationAction.navigationType == .linkActivated {
      if let u = navigationAction.request.url, ["https", "http"].contains(u.scheme) {
        NSWorkspace.shared.open(u)
      }
      decisionHandler(.cancel)
    } else {
      decisionHandler(.allow)
    }
  }
  func exportPDF(to url: URL, options: PDFOptions) async throws {
    guard loaded, let ready = try await web.evaluateJavaScript("window.ready === true") as? Bool,
      ready
    else { throw AppError.message(T("预览仍在加载", "Preview is loading")) }
    let size =
      options.letter ? CGSize(width: 612, height: 792) : CGSize(width: 595.28, height: 841.89)
    var bounds = CGRect(
      origin: .zero, size: options.landscape ? CGSize(width: size.height, height: size.width) : size
    )
    let area = bounds.insetBy(dx: options.margin, dy: options.margin)
    let printable = PreviewController()
    let width = area.width / 0.75
    printable.web.frame = CGRect(x: 0, y: 0, width: width, height: 1)
    printable.update(text: pending, path: root?.appendingPathComponent("document.md").path)
    var printReady = false
    for _ in 0..<100 {
      try await Task.sleep(nanoseconds: 100_000_000)
      if printable.loaded,
        let value = try? await printable.web.evaluateJavaScript("window.ready === true"),
        value as? Bool == true
      {
        printReady = true
        break
      }
    }
    guard printReady else {
      throw AppError.message(T("PDF 内容加载超时", "PDF content loading timed out"))
    }
    let height =
      try await printable.web.evaluateJavaScript(
        "document.body.style.fontSize=\"\(options.fontSize/0.75)px\";document.body.style.lineHeight=\"\(options.lineHeight)\";document.body.style.margin=\"0\";document.body.style.padding=\"0\";document.body.style.maxWidth=\"none\";Math.ceil(document.documentElement.scrollHeight);"
      ) as? Double ?? 1
    let configuration = WKPDFConfiguration()
    configuration.rect = CGRect(x: 0, y: 0, width: width, height: max(1, height))
    let source = try await printable.web.pdf(configuration: configuration)
    guard let provider = CGDataProvider(data: source as CFData),
      let original = CGPDFDocument(provider), let sourcePage = original.page(at: 1)
    else { throw AppError.message("PDF rendering failed") }
    let sourceBounds = sourcePage.getBoxRect(.mediaBox)
    let scale = area.width / sourceBounds.width
    let pageCount = max(1, Int(ceil(sourceBounds.height * scale / area.height)))
    let output = NSMutableData()
    guard let consumer = CGDataConsumer(data: output),
      let ctx = CGContext(consumer: consumer, mediaBox: &bounds, nil)
    else { throw AppError.message("PDF writer failed") }
    for index in 0..<pageCount {
      ctx.beginPDFPage(nil)
      ctx.saveGState()
      ctx.clip(to: area)
      ctx.translateBy(
        x: area.minX, y: area.maxY - sourceBounds.height * scale + Double(index) * area.height)
      ctx.scaleBy(x: scale, y: scale)
      ctx.drawPDFPage(sourcePage)
      ctx.restoreGState()
      ctx.endPDFPage()
    }
    ctx.closePDF()
    guard let pdf = PDFDocument(data: output as Data) else {
      throw AppError.message("PDF serialization failed")
    }
    for index in 0..<pdf.pageCount {
      guard let page = pdf.page(at: index) else { continue }
      let bounds = page.bounds(for: .mediaBox)
      for (text, y) in [
        (options.header, bounds.height - 22),
        (options.footer + (options.numbers ? "  \(index+1) / \(pdf.pageCount)" : ""), 10.0),
      ] {
        if !text.isEmpty {
          let a = PDFAnnotation(
            bounds: CGRect(
              x: options.margin, y: y, width: bounds.width - options.margin * 2, height: 14),
            forType: .freeText, withProperties: nil)
          a.contents = text
          a.font = NSFont.systemFont(ofSize: 9)
          a.fontColor = .darkGray
          a.color = .clear
          let border = PDFBorder()
          border.lineWidth = 0
          a.border = border
          page.addAnnotation(a)
        }
      }
    }
    guard let data = pdf.dataRepresentation() else {
      throw AppError.message("PDF serialization failed")
    }
    try data.write(to: url, options: .atomic)
  }

}
struct PreviewHost: NSViewRepresentable {
  let controller: PreviewController
  let text: String
  let path: String?
  func makeNSView(context: Context) -> WKWebView {
    controller.update(text: text, path: path)
    return controller.web
  }
  func updateNSView(_ v: WKWebView, context: Context) {
    if controller.pending != text
      || controller.root != path.map({ URL(fileURLWithPath: $0).deletingLastPathComponent() })
    {
      controller.update(text: text, path: path)
    }
  }
}
struct FileNode: Identifiable {
  let url: URL
  var id: String { url.path }
  var folder: Bool { (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
  var children: [FileNode]? {
    guard folder else { return nil }
    return
      ((try? FileManager.default.contentsOfDirectory(
        at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? [])
      .sorted {
        $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
      }.map { FileNode(url: $0) }
  }
}
final class MarkdownTextView: NSTextView {
  override func insertNewline(_ sender: Any?) {
    let ns = string as NSString
    let range = ns.lineRange(for: NSRange(location: selectedRange().location, length: 0))
    let line = ns.substring(with: range)
    let indent = String(line.prefix(while: { $0 == " " || $0 == "\t" }))
    super.insertNewline(sender)
    if !indent.isEmpty { insertText(indent, replacementRange: selectedRange()) }
  }
  override func menu(for event: NSEvent) -> NSMenu? {
    let m = super.menu(for: event)
    let item = NSMenuItem(
      title: T("用 AI 修改选区", "Edit Selection with AI"), action: #selector(askAI), keyEquivalent: "")
    item.target = self
    m?.addItem(item)
    return m
  }
  var ask: (() -> Void)?
  @objc func askAI() { ask?() }
}
final class LineRuler: NSRulerView {
  override func drawHashMarksAndLabels(in rect: NSRect) {
    guard let view = clientView as? NSTextView, let layout = view.layoutManager,
      let container = view.textContainer
    else { return }
    let ns = view.string as NSString
    if ns.length == 0 { return }
    var index = 0
    var line = 1
    let attrs: [NSAttributedString.Key: Any] = [
      .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
      .foregroundColor: NSColor.secondaryLabelColor,
    ]
    while index < max(ns.length, 1) {
      let glyph = layout.glyphIndexForCharacter(at: min(index, max(ns.length - 1, 0)))
      let r = layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
      let y = r.minY + view.textContainerInset.height - (scrollView?.contentView.bounds.minY ?? 0)
      if y >= rect.minY - 20, y <= rect.maxY + 20 {
        ("\(line)" as NSString).draw(at: NSPoint(x: 5, y: y), withAttributes: attrs)
      }
      if ns.length == 0 { break }
      index = NSMaxRange(ns.lineRange(for: NSRange(location: index, length: 0)))
      line += 1
    }
    _ = container
  }
}
struct DiffLine: Identifiable {
  let id: Int
  let text: String
  let kind: Int
}
enum LineDiff {
  static func rows(old: String, new: String) -> [DiffLine] {
    let a = old.components(separatedBy: "\n")
    let b = new.components(separatedBy: "\n")
    let delta = b.difference(from: a)
    var removed = Set<Int>()
    var inserted = Set<Int>()
    for c in delta {
      switch c {
      case .remove(let i, _, _): removed.insert(i)
      case .insert(let i, _, _): inserted.insert(i)
      }
    }
    var rows: [DiffLine] = []
    var i = 0
    var j = 0
    while i < a.count || j < b.count {
      if i < a.count, removed.contains(i) {
        rows.append(DiffLine(id: rows.count, text: "− " + a[i], kind: -1))
        i += 1
      } else if j < b.count, inserted.contains(j) {
        rows.append(DiffLine(id: rows.count, text: "+ " + b[j], kind: 1))
        j += 1
      } else if j < b.count {
        rows.append(DiffLine(id: rows.count, text: "  " + b[j], kind: 0))
        j += 1
        i += 1
      } else {
        i += 1
      }
    }
    return rows
  }
}
struct PDFOptions {
  var letter = false
  var landscape = false
  var margin = 36.0
  var fontSize = 16.0
  var lineHeight = 1.65
  var numbers = true
  var header = ""
  var footer = ""
}
struct PDFSettingsView: View {
  let controller: PreviewController
  @Environment(\.dismiss) var dismiss
  @State var options = PDFOptions()
  var body: some View {
    VStack {
      Text(T("导出 PDF", "Export PDF")).font(.title2)
      Form {
        Toggle("Letter (A4)", isOn: $options.letter)
        Toggle(T("横向", "Landscape"), isOn: $options.landscape)
        HStack {
          Text(T("页边距（点）", "Margins (points)"))
          Slider(value: $options.margin, in: 24...90, step: 6)
          Text("\(Int(options.margin))")
        }
        HStack {
          Text(T("字号", "Font Size"))
          Slider(value: $options.fontSize, in: 10...24, step: 1)
          Text("\(Int(options.fontSize))")
        }
        HStack {
          Text(T("行距", "Line Height"))
          Slider(value: $options.lineHeight, in: 1.2...2.2, step: 0.1)
        }
        TextField(T("页眉", "Header"), text: $options.header)
        TextField(T("页脚", "Footer"), text: $options.footer)
        Toggle(T("页码", "Page Numbers"), isOn: $options.numbers)
      }
      HStack {
        Button(T("取消", "Cancel")) { dismiss() }
        Spacer()
        Button(T("导出…", "Export…")) {
          let panel = NSSavePanel()
          panel.nameFieldStringValue = "MarkGPT.pdf"
          panel.allowedFileTypes = ["pdf"]
          if panel.runModal() == .OK, let url = panel.url {
            Task {
              do {
                try await controller.exportPDF(to: url, options: options)
                dismiss()
              } catch { controller.issue?(error.localizedDescription) }
            }
          }
        }.buttonStyle(.borderedProminent)
      }
    }.padding(24).frame(width: 520)
  }
}
