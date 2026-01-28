// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FluxTimer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FluxTimer", targets: ["FluxTimer"])
    ],
    targets: [
        .executableTarget(
            name: "FluxTimer",
            path: "Sources"
        )
    ]
)
