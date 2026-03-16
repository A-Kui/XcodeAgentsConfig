// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "XcodeAgentsConfig",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "XcodeAgentsConfig",
            targets: ["XcodeAgentsConfig"]
        )
    ],
    targets: [
        .executableTarget(
            name: "XcodeAgentsConfig",
            path: "Sources/XcodeAgentsConfig"
        )
    ]
)
