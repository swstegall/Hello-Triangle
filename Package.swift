// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "HelloTriangle",
  products: [
    .executable(name: "HelloTriangle", targets: ["HelloTriangle"])
  ],
  targets: [
    .systemLibrary(
      name: "CGLFW",
      pkgConfig: "glfw3",
      providers: [
        .brew(["glfw"])
      ]
    ),
    .target(
      name: "CGLAD",
      path: "Sources/CGlad",
      publicHeadersPath: "include"
    ),
    .target(
      name: "CGLLOADER",
      dependencies: ["CGLFW", "CGLAD"],
      publicHeadersPath: "."
    ),
    .executableTarget(
      name: "HelloTriangle",
      dependencies: ["CGLFW", "CGLAD", "CGLLOADER"],
      linkerSettings: [
        .linkedFramework("OpenGL")
      ]
    )
  ]
)
