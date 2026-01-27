// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LiquidTimer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LiquidTimer", targets: ["LiquidTimer"])
    ],
    targets: [
        .executableTarget(
            name: "LiquidTimer",
            path: "Sources"
        )
    ]
)
