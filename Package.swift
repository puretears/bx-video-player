// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BXVideoPlayer",
    platforms: [
      .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BXVideoPlayer",
            targets: ["BXVideoPlayer"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
      .package(url: "https://github.com/puretears/bx-slider-view", branch: "main"),
      .package(url: "https://github.com/puretears/bx-downloader", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BXVideoPlayer",
            dependencies: [
              .product(name: "BXSliderView", package: "bx-slider-view"),
              .product(name: "BXDownloader", package: "bx-downloader")
            ],
            resources: [
              .process("Assets/Resources.xcassets")
            ]
        ),
        .testTarget(
            name: "BXVideoPlayerTests",
            dependencies: ["BXVideoPlayer"]),
    ]
)
