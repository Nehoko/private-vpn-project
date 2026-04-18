// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PrivateVPNAdmin",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "PrivateVPNAdmin", targets: ["PrivateVPNAdmin"]),
    ],
    targets: [
        .executableTarget(
            name: "PrivateVPNAdmin",
            path: "Sources/AdminMacOS"
        ),
    ]
)
