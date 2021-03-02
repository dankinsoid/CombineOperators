// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "CombineOperators",
    platforms: [
			.iOS(.v12)
    ],
    products: [
			.library(name: "CombineOperators", targets: ["CombineOperators"]),
			.library(name: "CombineCocoa", targets: ["CombineCocoa"])
    ],
    dependencies: [
			.package(url: "https://github.com/dankinsoid/VDKit.git", from: "1.13.0"),
			.package(url: "https://github.com/dankinsoid/VDCodable.git", from: "1.0.11")
    ],
    targets: [
			.target(name: "CombineOperators", dependencies: ["VDKit"]),
			.target(name: "CombineCocoaRuntime", dependencies: []),
			.target(name: "CombineCocoa", dependencies: ["CombineCocoaRuntime", "CombineOperators", "VDKit",  "VDCodable"]),
			.testTarget(name: "CombineOperatorsTests", dependencies: ["CombineOperators", "CombineCocoa"])
    ]
)
