// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RetroTV",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // An xtool project should contain exactly one library product,
        // representing the main app.
        .library(
            name: "RetroTV",
            targets: ["RetroTV"]
        ),
    ],
    dependencies: [
        // Generates typed Swift (L10n.helloWorld) from the strings in
        // Sources/<Target>/Resources at build time. Config: Sources/<Target>/swiftgen.yml.
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.2"),
    ],
    targets: [
        // The whole app: the MyRetroTVs living room and decade sets, plus the
        // MTV Rewind player (wantmymtv.org) in Sources/RetroTV/MTV.
        .target(
            name: "RetroTV",
            exclude: ["swiftgen.yml"],
            resources: [
                .process("Resources"),
            ],
            plugins: [
                .plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin"),
            ]
        ),
    ]
)
