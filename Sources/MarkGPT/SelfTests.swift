import AppKit
import CryptoKit
import Foundation
import PDFKit

enum SelfTests {
  static func run() throws {
    func check(_ ok: Bool, _ name: String) throws {
      if !ok { throw AppError.message(name) }
      print("PASS: \(name)")
    }
    var d = Draft(text: "# 原文\nhello", saved: "# 原文\nhello")
    let p = EditProposal(document: d.id, original: d.text, replacement: "# 修改\nworld")
    try EditSafety.apply(p, to: &d)
    try check(d.text == p.replacement && d.dirty, "AI edit applies to captured document")
    do {
      try EditSafety.apply(p, to: &d)
      throw AppError.message("Conflict was accepted")
    } catch { try check(d.text == p.replacement, "Conflict preserves manual text") }
    let wrong = EditProposal(document: UUID(), original: d.text, replacement: "bad")
    do {
      try EditSafety.apply(wrong, to: &d)
      throw AppError.message("Wrong target accepted")
    } catch { try check(d.text == p.replacement, "Wrong document rejected") }
    try check(
      try EditSafety.replacement("```markdown\n# 你好\n```") == "# 你好", "Markdown response extraction"
    )
    var rejected = false
    do { _ = try EditSafety.replacement("partial reply") } catch { rejected = true }
    try check(rejected, "Incomplete reply rejected")
    let copy = try JSONDecoder().decode(Draft.self, from: JSONEncoder().encode(d))
    try check(copy.text == d.text && copy.saved == d.saved, "Draft recovery round trip")
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
      "markgpt-test-" + UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: folder) }
    let store = CredentialStore(directory: folder)
    try store.update { $0.apiKey = "fixture-only" }
    try check(try store.read().apiKey == "fixture-only", "JSON credential read/write")
    let attrs = try FileManager.default.attributesOfItem(atPath: store.url.path)
    try check(
      (attrs[.posixPermissions] as? NSNumber)?.intValue == 0o600, "Credentials permissions 0600")
    try "broken".write(to: store.url, atomically: true, encoding: .utf8)
    rejected = false
    do { try store.update { $0.apiKey = "replacement" } } catch { rejected = true }
    try check(
      rejected && (try String(contentsOf: store.url)) == "broken", "Corrupt credentials preserved")
    try check(
      Safety.redact("api_key=sk-fixture123456") != "api_key=sk-fixture123456", "Outgoing redaction")
    let verifier = "fixture-verifier"
    try check(
      ChatGPTOAuth.challenge(verifier)
        == ChatGPTOAuth.base64url(Data(SHA256.hash(data: Data(verifier.utf8)))), "OAuth PKCE")
    for asset in ["marked.js", "purify.js", "mermaid.js", "katex.js", "katex.css", "highlight.js"] {
      try check(
        Bundle.module.url(forResource: "Web", withExtension: nil).map {
          FileManager.default.fileExists(atPath: $0.appendingPathComponent(asset).path)
        } == true, "Bundled asset \(asset)")
    }
    print("All self-tests passed")
  }
}
@MainActor enum RenderTests {
  static func run(_ p: PreviewController) async {
    do {
      var previewFailure: String?
      p.issue = { previewFailure = $0 }
      p.update(
        text:
          "# 中文测试\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\n$$E=mc^2$$\n\n```mermaid\ngraph LR\n A-->B\n```\n\n```swift\nlet value = 1\n```\n\n<script>window.compromised=true</script>",
        path: nil)
      var ready = false
      for _ in 0..<60 {
        try await Task.sleep(nanoseconds: 250_000_000)
        if p.loaded, let value = try? await p.web.evaluateJavaScript("window.ready === true"),
          value as? Bool == true
        {
          ready = true
          break
        }
      }
      guard ready, previewFailure == nil else {
        throw AppError.message("Preview did not become ready: \(previewFailure ?? "timeout")")
      }
      let value = try await p.web.evaluateJavaScript(
        "JSON.stringify({heading:document.querySelector('h1')?.textContent,table:!!document.querySelector('table'),math:!!document.querySelector('.katex'),diagram:!!document.querySelector('.mermaid svg'),code:!!document.querySelector('.hljs'),safe:window.compromised!==true})"
      )
      guard let string = value as? String, let data = string.data(using: .utf8),
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        result["heading"] as? String == "中文测试",
        ["table", "math", "diagram", "code", "safe"].allSatisfy({ result[$0] as? Bool == true })
      else { throw AppError.message("Render checks failed: \(String(describing:value))") }
      let pdf = try await p.web.pdf(configuration: .init())
      guard pdf.starts(with: Data("%PDF".utf8)), pdf.count > 1000 else {
        throw AppError.message("PDF generation failed")
      }
      try pdf.write(to: URL(fileURLWithPath: "/private/tmp/markgpt-render-test.pdf"))
      print(
        "PASS: WebKit Chinese, table, math, Mermaid, highlighting, sanitization and PDF (\(pdf.count) bytes)"
      )
      var options = PDFOptions()
      options.header = "MarkGPT test"
      let output = URL(fileURLWithPath: "/private/tmp/markgpt-paginated-test.pdf")
      try await p.exportPDF(to: output, options: options)
      guard let paginated = PDFDocument(url: output), paginated.pageCount > 0 else {
        throw AppError.message("Paginated PDF failed")
      }
      print(
        "PASS: Paginated PDF export with header and page numbers (\(paginated.pageCount) pages)")
      guard paginated.pageCount == 1 else {
        throw AppError.message("Short PDF unexpectedly spans multiple pages")
      }
      if let page = paginated.page(at: 0) {
        let image = page.thumbnail(of: NSSize(width: 900, height: 1273), for: .mediaBox)
        if let data = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: data) {
          try bitmap.representation(using: .png, properties: [:])?.write(
            to: URL(fileURLWithPath: "/private/tmp/markgpt-pdf-preview.png"))
        }
      }
      let folder = FileManager.default.temporaryDirectory.appendingPathComponent(
        "markgpt-images-" + UUID().uuidString)
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      defer { try? FileManager.default.removeItem(at: folder) }
      let image = NSImage(size: NSSize(width: 8, height: 8))
      image.lockFocus()
      NSColor.systemBlue.setFill()
      NSBezierPath(rect: NSRect(x: 0, y: 0, width: 8, height: 8)).fill()
      image.unlockFocus()
      let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
      try bitmap.representation(using: .png, properties: [:])!.write(
        to: folder.appendingPathComponent("image.png"))
      p.update(
        text: "# Local image\n\n![local](image.png)",
        path: folder.appendingPathComponent("document.md").path)
      ready = false
      for _ in 0..<40 {
        try await Task.sleep(nanoseconds: 250_000_000)
        if p.loaded,
          let value = try? await p.web.evaluateJavaScript(
            "window.ready === true && document.querySelector('img')?.naturalWidth > 0"),
          value as? Bool == true
        {
          ready = true
          break
        }
      }
      guard ready else { throw AppError.message("Relative local image failed") }
      print("PASS: Relative local image")
      if ProcessInfo.processInfo.environment["MARKGPT_FIXTURE_URL"] != nil {
        try await ProviderTests.run()
      }
      exit(0)
    } catch {
      fputs("Render test failed: \(error)\n", stderr)
      exit(1)
    }
  }
}
@MainActor enum ProviderTests {
  static func run() async throws {
    guard let url = ProcessInfo.processInfo.environment["MARKGPT_FIXTURE_URL"],
      ProcessInfo.processInfo.environment["MARKGPT_DATA_DIR"] != nil
    else { throw AppError.message("Fixture environment missing") }
    let w = Workspace()
    w.preferences.provider = .custom
    w.preferences.endpoint = url
    w.preferences.model = "fixture"
    w.preferences.redactBeforeSending = false
    w.changed("# Original")
    w.input = "Improve this document"
    w.send(edit: true)
    for _ in 0..<60 {
      if !w.busy { break }
      try await Task.sleep(nanoseconds: 100_000_000)
    }
    guard let proposal = w.proposal, w.document?.text == "# Original", w.error == nil else {
      throw AppError.message("Review workflow failed: \(w.error ?? "missing proposal")")
    }
    w.apply(proposal)
    guard w.document?.text == "# Revised\n\nFixture edit." else {
      throw AppError.message("Apply workflow failed")
    }
    w.undoAI()
    guard w.document?.text == "# Original" else { throw AppError.message("AI undo failed") }
    w.autoApply = true
    w.input = "Improve"
    w.send(edit: true)
    w.changed("# Manual concurrent edit")
    for _ in 0..<60 {
      if !w.busy { break }
      try await Task.sleep(nanoseconds: 100_000_000)
    }
    guard w.document?.text == "# Manual concurrent edit", let conflict = w.proposal else {
      throw AppError.message("Automatic edit overwrote manual content")
    }
    w.apply(conflict)
    guard w.document?.text == "# Manual concurrent edit", w.error != nil else {
      throw AppError.message("Conflict application accepted")
    }
    w.error = nil
    w.proposal = nil
    w.input = "Improve again"
    w.send(edit: true)
    for _ in 0..<60 {
      if !w.busy { break }
      try await Task.sleep(nanoseconds: 100_000_000)
    }
    guard w.document?.text == "# Revised\n\nFixture edit." else {
      throw AppError.message("Automatic application failed")
    }
    w.input = "Hello"
    w.send()
    for _ in 0..<60 {
      if !w.busy { break }
      try await Task.sleep(nanoseconds: 100_000_000)
    }
    guard w.currentChat.messages.last?.content == "Fixture streaming reply." else {
      throw AppError.message("Streaming chat failed")
    }
    print(
      "PASS: Real loopback SSE, review/apply, AI undo, auto-apply, concurrent edit conflict and chat"
    )
  }
}
