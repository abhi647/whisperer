// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Whisperer",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Whisperer", targets: ["Whisperer"])
    ],
    targets: [
        .executableTarget(
            name: "Whisperer",
            path: "Sources/Whisperer"
        ),
        .testTarget(
            name: "WhispererTests",
            dependencies: ["Whisperer"],
            path: "Tests/WhispererTests"
        )
    ]
)
