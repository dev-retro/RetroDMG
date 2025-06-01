#!/usr/bin/env swift
import Foundation

let slangBuild = Process()
slangBuild.executableURL = URL(fileURLWithPath: "/usr/bin/env")
slangBuild.arguments = ["slangc", "-target", "metal", "-o", "./Sources/RetroDMGApp/platforms/macOS/Shaders/Shaders.metal", "./Sources/RetroDMGApp/Shaders/Shaders.slang"]
do{
  try slangBuild.run()
} catch {}