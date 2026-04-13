// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "QueryTool",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.13.3")
    ],
    targets: [
        .executableTarget(
            name: "QueryTool",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "."
        )
    ]
)
