// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Zonelet",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Zonelet", targets: ["Zonelet"])
    ],
    targets: [
        .executableTarget(
            name: "Zonelet",
            path: "Sources/Zonelet"
        ),
        .testTarget(
            name: "ZoneletTests",
            dependencies: ["Zonelet"]
        )
    ]
)
