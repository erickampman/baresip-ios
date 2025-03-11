// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "baresip-ios",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "baresip-ios",
            targets: ["baresip-ios"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/erickampman/re-ios.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "baresip-ios",
            dependencies: ["re-ios"],
            path: "src",
            exclude: ["test", "docs"],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .define("BARESIP_IOS")
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("AVFoundation"),
                .linkedLibrary("resolv") // Optional if needed
            ]
        ),
        .testTarget(
            name: "baresip-iosTests",
            dependencies: ["baresip-ios"],
            path: "test"
        )
    ]
)

