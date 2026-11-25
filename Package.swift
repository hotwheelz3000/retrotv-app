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
        // The app: the MyRetroTVs living room with the seven decade TV sets.
        .target(
            name: "RetroTV",
            dependencies: ["MTVRewind"],
            exclude: ["swiftgen.yml"],
            resources: [
                .process("Resources"),
            ],
            plugins: [
                .plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin"),
            ]
        ),
        // The MTV Rewind player (wantmymtv.org), opened from the living room.
        // Its own module, so its Theme, sheets and web view keep their names.
        .target(
            name: "MTVRewind",
            exclude: ["swiftgen.yml"],
            resources: [
                .process("Resources"),
                // The icon on the loading screen.
                .copy("LaunchIcon.png"),
            ],
            plugins: [
                .plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin"),
            ]
        ),
    ]
)
