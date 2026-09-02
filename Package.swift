// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Zonelet",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Zonelet", targets: ["Zonelet"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            exact: "2.9.4"
        )
    ],
    targets: [
        .executableTarget(
            name: "Zonelet",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/Zonelet"
        ),
        .testTarget(
            name: "ZoneletTests",
            dependencies: ["Zonelet"]
        )
    ]
)
