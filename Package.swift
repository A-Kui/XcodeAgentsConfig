// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "kXcodeAgentsConfig",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "kXcodeAgentsConfig",
            targets: ["XcodeAgentsConfig"]
        )
    ],
    targets: [
        .executableTarget(
            name: "XcodeAgentsConfig",
            path: "Sources/XcodeAgentsConfig"
        ),
        .testTarget(
            name: "XcodeAgentsConfigTests",
            dependencies: ["XcodeAgentsConfig"],
            path: "Tests/XcodeAgentsConfigTests"
        )
    ]
)
