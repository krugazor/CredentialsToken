// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sample",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.9.0"),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.9.0"),
        .package(url: "https://github.com/RuntimeTools/SwiftMetrics.git", from: "2.6.4"),
        .package(url: "https://github.com/IBM-Swift/Health.git", from: "1.0.5"),
        .package(name:"KituraStencil", url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", from: "1.11.1"),
        .package(name: "KituraMarkdown", url: "https://github.com/IBM-Swift/Kitura-Markdown.git", from: "1.1.2"),
        .package(name: "Kitura-CredentialsHTTP", url: "https://github.com/IBM-Swift/Kitura-CredentialsHTTP.git", from: "2.1.3"),
        .package(name: "Kitura-Session", url: "https://github.com/IBM-Swift/Kitura-Session.git", from: "3.3.4"),
        .package(path: ".."),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Sample",
            dependencies: ["Kitura","SwiftMetrics","Health",.product(name: "KituraMarkdown", package:"KituraMarkdown"), "KituraStencil", .product(name: "CredentialsHTTP", package: "Kitura-CredentialsHTTP"), .product(name: "KituraSession", package: "Kitura-Session"),"HeliumLogger", "CredentialsToken"]),
    ]
)
