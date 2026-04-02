// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Kairu",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Kairu",
            path: "Sources/Kairu",
            resources: [.process("Resources")]
        )
    ]
)
