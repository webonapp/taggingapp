// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VideoAnalysisApp",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "VideoAnalysisApp", targets: ["VideoAnalysisApp"])
    ],
    targets: [
        .executableTarget(
            name: "VideoAnalysisApp",
            path: "Sources/VideoAnalysisApp"
        ),
        .testTarget(
            name: "VideoAnalysisAppTests",
            dependencies: ["VideoAnalysisApp"],
            path: "Tests/VideoAnalysisAppTests"
        )
    ]
)
