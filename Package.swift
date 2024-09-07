// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "planify_mac_client",
    platforms: [
        .macOS(.v10_12)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "YourProjectName",
            dependencies: ["HotKey"]
        )
    ]
)
