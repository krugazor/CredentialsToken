// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CredentialsToken",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CredentialsToken",
            targets: ["CredentialsToken"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
       .package(url: "https://github.com/IBM-Swift/Kitura-Session.git", from: "3.3.0"),
       .package(url: "https://github.com/IBM-Swift/Kitura-Credentials", from: "2.5.0"),
       .package(url: "https://github.com/krugazor/DictionaryCoding", from: "0.2.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CredentialsToken",
            dependencies: [.product(name: "KituraSession", package: "Kitura-Session"),.product(name: "Credentials", package: "Kitura-Credentials"), "DictionaryCoding"]),
        .testTarget(
            name: "CredentialsTokenTests",
            dependencies: ["CredentialsToken"]),
    ]
)
