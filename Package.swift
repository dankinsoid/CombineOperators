// swift-tools-version:5.6
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
			.package(url: "https://github.com/dankinsoid/NSMethodsObservation.git", from: "1.2.0"),
    ],
    targets: [
			.target(name: "CombineOperators", dependencies: ["NSMethodsObservation"]),
			.target(name: "CombineCocoa", dependencies: ["CombineOperators", "NSMethodsObservation"]),
			.testTarget(name: "CombineOperatorsTests", dependencies: ["CombineOperators", "CombineCocoa"])
    ]
)
