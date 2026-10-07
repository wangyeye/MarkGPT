// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "MarkGPT", platforms: [.macOS(.v13)], products: [.executable(name: "MarkGPT", targets: ["MarkGPT"])], targets: [.executableTarget(name: "MarkGPT", resources: [.copy("Web")])])
