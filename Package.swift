// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "CombineOperators",
    platforms: [
			.iOS(.v13)
    ],
    products: [
			.library(name: "CombineOperators", targets: ["CombineOperators"]),
			.library(name: "CombineCocoa", targets: ["CombineCocoa"])
    ],
    dependencies: [
        .package(url: "https://github.com/dankinsoid/VDKit.git", from: "1.13.0"),
    ],
    targets: [
			.target(name: "CombineOperators", dependencies: ["VDKit"]),
			.target(name: "CombineCocoaRuntime", dependencies: []),
			.target(name: "CombineCocoa", dependencies: ["CombineCocoaRuntime", "CombineOperators", "VDKit"]),
			.testTarget(name: "CombineOperatorsTests", dependencies: ["CombineOperators", "CombineCocoa"])
    ]
)
