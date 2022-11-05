// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "CombineOperators",
    platforms: [
        .iOS(.v13)
    ],
    products: [
			.library(name: "CombineOperators", targets: ["CombineOperators"]),
			.library(name: "CombineCocoa", targets: ["CombineCocoa"]),
    ],
    dependencies: [
    ],
    targets: [
			.target(name: "CombineOperators", dependencies: []),
			.target(name: "CombineCocoa", dependencies: ["CombineOperators"]),
    ]
)
