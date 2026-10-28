// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenVideoPlayer",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "OpenVideoPlayerCore",
            targets: ["OpenVideoPlayerCore"]
        )
    ],
    targets: [
        .target(
            name: "OpenVideoPlayerCore",
            path: "OpenVideoPlayer",
            exclude: [
                "App",
                "Resources/Info.plist",
                "Resources/Config.plist.template",
                "Resources/Assets.xcassets"
            ]
        ),
        .testTarget(
            name: "OpenVideoPlayerTests",
            dependencies: ["OpenVideoPlayerCore"],
            path: "Tests/OpenVideoPlayerTests"
        )
    ]
)
