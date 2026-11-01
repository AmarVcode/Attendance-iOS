// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Attendance",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Attendance",
            targets: ["Attendance"]
        )
    ],
    targets: [
        .target(
            name: "Attendance",
            path: "Attendance"
        )
    ]
)

