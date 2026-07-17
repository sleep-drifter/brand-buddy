// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RadialLayout",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "RadialLayout", targets: ["RadialLayout"])
    ],
    targets: [
        .target(name: "RadialLayout")
    ]
)
