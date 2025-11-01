// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
	name: "CombineOperators",
	platforms: [
		.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6),
	],
	products: [
		.library(name: "CombineOperators", targets: ["CombineOperators"]),
		.library(name: "CombineCocoa", targets: ["CombineCocoa"]),
	],
	dependencies: [
	],
	targets: [
		.target(
			name: "CombineOperators",
			dependencies: [],
			swiftSettings: [
				.unsafeFlags(["-package-name", "CombineOperators"]),
			]
		),
		.target(
			name: "CombineCocoa",
			dependencies: ["CombineOperators"],
			swiftSettings: [
				.unsafeFlags(["-package-name", "CombineOperators"]),
			]
		),
		.target(
			name: "TestUtilities",
			dependencies: ["CombineOperators"],
			path: "Tests/TestUtilities"
		),
		.testTarget(
			name: "CombineOperatorsTests",
			dependencies: ["CombineOperators", "TestUtilities"]
		),
		.testTarget(
			name: "CombineCocoaTests",
			dependencies: ["CombineCocoa", "CombineOperators", "TestUtilities"]
		),
	]
)
