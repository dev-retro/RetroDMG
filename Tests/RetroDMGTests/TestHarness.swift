//
//  TestHarness.swift
//  RetroDMG
//
//  Created by GitHub Copilot on 20/7/2025.
//
//  Game Boy Test ROM Harness for RetroDMG
//  Provides functionality to run test ROMs, capture framebuffer output,
//  compare against reference images, and generate test reports.
//

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import RetroDMG

/// Test harness for running GameBoy test ROMs and comparing framebuffer output
public class TestHarness {
    
    /// Configuration for test execution
    public struct TestConfig {
        /// Duration to run the test (in seconds)
        public let duration: TimeInterval?
        /// Specific opcode to stop execution on (hex value)
        public let stopOnOpcode: UInt8?
        /// Maximum number of frames to capture
        public let maxFrames: Int
        /// Output directory for captured images
        public let outputDirectory: URL
        /// Reference image path for comparison
        public let referenceImagePath: URL?
        /// Test ROM name for identification
        public let testName: String
        
        public init(
            duration: TimeInterval? = nil,
            stopOnOpcode: UInt8? = nil,
            maxFrames: Int = 1000,
            outputDirectory: URL,
            referenceImagePath: URL? = nil,
            testName: String
        ) {
            self.duration = duration
            self.stopOnOpcode = stopOnOpcode
            self.maxFrames = maxFrames
            self.outputDirectory = outputDirectory
            self.referenceImagePath = referenceImagePath
            self.testName = testName
        }
    }
    
    /// Result of test execution
    public struct TestResult {
        public let testName: String
        public let success: Bool
        public let framesCaptured: Int
        public let executionTime: TimeInterval
        public let stopReason: StopReason
        public let outputImagePath: URL?
        public let referenceImagePath: URL?
        public let comparisonResult: ImageComparisonResult?
        public let errorMessage: String?
        public let capturedFramePath: URL?
        
        public enum StopReason: Equatable {
            case duration
            case opcode(UInt8)
            case maxFrames
            case error(String)
        }
    }
    
    /// Result of image comparison
    public struct ImageComparisonResult {
        public let identical: Bool
        public let pixelDifferences: Int
        public let totalPixels: Int
        public let differencePercentage: Double
        
        public var percentageString: String {
            return String(format: "%.2f%%", differencePercentage * 100)
        }
    }
    
    private let emulator: RetroDMG
    
    public init() {
        self.emulator = RetroDMG()
    }
    
    /// Run a test ROM with the specified configuration
    public func runTest(romData: [UInt8], config: TestConfig) async -> TestResult {
        let startTime = Date()
        
        var stopReason: TestResult.StopReason = .duration
        do {
            // Create output directory if it doesn't exist
            try FileManager.default.createDirectory(at: config.outputDirectory, withIntermediateDirectories: true)

            // Remove old output images
            if let files = try? FileManager.default.contentsOfDirectory(at: config.outputDirectory, includingPropertiesForKeys: nil) {
                for file in files where file.pathExtension.lowercased() == "png" {
                    try? FileManager.default.removeItem(at: file)
                }
            }

            // Load ROM into emulator
            emulator.load(file: romData)
            
            // Set up debug mode if we need to monitor opcodes
            if config.stopOnOpcode != nil {
                emulator.debug(enabled: true)
            }
            
            // Start emulation
            _ = emulator.start()
            

            let endTime = config.duration.map { startTime.addingTimeInterval($0) }

            while true {
                // Check duration stop condition
                if let endTime = endTime, Date() > endTime {
                    stopReason = .duration
                    break
                }

                // FIXME: This won't work as this doesn't check every opcode.
                // Check opcode stop condition
                if let targetOpcode = config.stopOnOpcode {
                    let currentPC = emulator.getCurrentPC()
                    if currentPC != 0 { // Avoid initial state
                        let currentOpcode = emulator.readMemory(at: currentPC)
                        if currentOpcode == targetOpcode {
                            stopReason = .opcode(targetOpcode)
                            break
                        }
                    }
                }

                // Small delay to prevent excessive CPU usage
                try await Task.sleep(nanoseconds: 16_666_667) // ~60 FPS
                // Add a break condition for maxFrames if needed
                // (Currently only one frame is captured after stop)
            }


            // Only capture and save the final framebuffer after stop condition
            let finalFrameBuffer = emulator.viewPort()
            let outputImagePath = config.outputDirectory.appendingPathComponent("\(config.testName)-output.png")

            do {
                try saveFramebufferAsPNG(frameBuffer: finalFrameBuffer, to: outputImagePath)
            } catch {
                _ = emulator.stop()
                return TestResult(
                    testName: config.testName,
                    success: false,
                    framesCaptured: 1,
                    executionTime: Date().timeIntervalSince(startTime),
                    stopReason: .error("Failed to save output image: \(error.localizedDescription)"),
                    outputImagePath: nil,
                    referenceImagePath: config.referenceImagePath,
                    comparisonResult: nil,
                    errorMessage: error.localizedDescription,
                    capturedFramePath: outputImagePath
                )
            }

            // Stop emulation
            _ = emulator.stop()
            let executionTime = Date().timeIntervalSince(startTime)
            

            // Compare with reference image if provided
            var comparisonResult: ImageComparisonResult? = nil
            var success = true

            if let referenceImagePath = config.referenceImagePath {
                do {
                    comparisonResult = try compareImages(
                        referenceImagePath: referenceImagePath,
                        outputImagePath: outputImagePath
                    )
                    if let result = comparisonResult {
                        success = result.identical
                    } else {
                        success = false
                        return TestResult(
                            testName: config.testName,
                            success: false,
                            framesCaptured: 1,
                            executionTime: executionTime,
                            stopReason: stopReason,
                            outputImagePath: outputImagePath,
                            referenceImagePath: referenceImagePath,
                            comparisonResult: nil,
                            errorMessage: "Image comparison result is nil.",
                            capturedFramePath: outputImagePath
                        )
                    }
                } catch {
                    return TestResult(
                        testName: config.testName,
                        success: false,
                        framesCaptured: 1,
                        executionTime: executionTime,
                        stopReason: stopReason,
                        outputImagePath: outputImagePath,
                        referenceImagePath: referenceImagePath,
                        comparisonResult: nil,
                        errorMessage: "Failed to compare images: \(error.localizedDescription)",
                        capturedFramePath: outputImagePath
                    )
                }
            }

            return TestResult(
                testName: config.testName,
                success: success,
                framesCaptured: 1,
                executionTime: executionTime,
                stopReason: stopReason,
                outputImagePath: outputImagePath,
                referenceImagePath: config.referenceImagePath,
                comparisonResult: comparisonResult,
                errorMessage: nil,
                capturedFramePath: outputImagePath
            )
            
        } catch {
            _ = emulator.stop()
            return TestResult(
                testName: config.testName,
                success: false,
                framesCaptured: 0,
                executionTime: Date().timeIntervalSince(startTime),
                stopReason: stopReason,
                outputImagePath: nil,
                referenceImagePath: config.referenceImagePath,
                comparisonResult: nil,
                errorMessage: error.localizedDescription,
                capturedFramePath: nil
            )
        }
    }
    
    /// Save GameBoy framebuffer as PNG image
    private func saveFramebufferAsPNG(frameBuffer: [Int], to url: URL) throws {
        let width = 160
        let height = 144
        
        guard frameBuffer.count == width * height else {
            throw TestHarnessError.invalidFramebufferSize
        }
        
        // Blargg DMG test ROM color mapping (official):
        // 0=White (#FFFFFF), 1=Light Gray (#AAAAAA), 2=Dark Gray (#555555), 3=Black (#000000)
        let colorMap: [(UInt8, UInt8, UInt8)] = [
            (0xFF, 0xFF, 0xFF), // White
            (0xAA, 0xAA, 0xAA), // Light Gray
            (0x55, 0x55, 0x55), // Dark Gray
            (0x00, 0x00, 0x00)  // Black
        ]

        var pixelData = [UInt8]()
        for pixel in frameBuffer {
            let colorIndex = min(3, max(0, pixel)) // Clamp to valid range
            let (r, g, b) = colorMap[colorIndex]
            pixelData.append(r) // Red
            pixelData.append(g) // Green
            pixelData.append(b) // Blue
            pixelData.append(0xFF)      // Alpha
        }
        
        // Create CGImage from pixel data
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        let bitsPerPixel = bytesPerPixel * bitsPerComponent
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw TestHarnessError.colorSpaceCreationFailed
        }
        
        guard let dataProvider = CGDataProvider(data: Data(pixelData) as CFData) else {
            throw TestHarnessError.dataProviderCreationFailed
        }
        
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw TestHarnessError.imageCreationFailed
        }
        
        // Save as PNG
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw TestHarnessError.destinationCreationFailed
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil)
        
        if !CGImageDestinationFinalize(destination) {
            throw TestHarnessError.imageSaveFailed
        }
    }
    
    /// Compare framebuffer with reference image
private func compareImages(referenceImagePath: URL, outputImagePath: URL) throws -> ImageComparisonResult {
    let width = 160
    let height = 144
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        throw TestHarnessError.colorSpaceCreationFailed
    }

    func getPixelData(_ image: CGImage) throws -> [UInt8] {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw TestHarnessError.contextCreationFailed
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data else {
            throw TestHarnessError.pixelDataExtractionFailed
        }
        let bufferPointer = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        return Array(UnsafeBufferPointer(start: bufferPointer, count: width * height * 4))
    }

    do {
        // Load reference image directly from the provided URL
        let referenceImageData = try Data(contentsOf: referenceImagePath)
        guard let referenceProvider = CGDataProvider(data: referenceImageData as CFData),
              let referenceImage = CGImage(pngDataProviderSource: referenceProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            print("[ERROR] Could not create CGImage from reference image data at: \(referenceImagePath.path)")
            throw TestHarnessError.referenceImageLoadFailed
        }
        // Load output image from provided path
        let outputImageData = try Data(contentsOf: outputImagePath)
        guard let outputProvider = CGDataProvider(data: outputImageData as CFData),
              let outputImage = CGImage(pngDataProviderSource: outputProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            print("[ERROR] Could not create CGImage from output image data at: \(outputImagePath.path)")
            throw TestHarnessError.referenceImageLoadFailed
        }
        guard referenceImage.width == width && referenceImage.height == height else {
            throw TestHarnessError.referenceDimensionMismatch
        }
        guard outputImage.width == width && outputImage.height == height else {
            throw TestHarnessError.referenceDimensionMismatch
        }
        let referenceBytes = try getPixelData(referenceImage)
        let outputBytes = try getPixelData(outputImage)
        var differences = 0
        let totalPixels = width * height
        let tolerance: UInt8 = 8
        for i in 0..<totalPixels {
            let offset = i * 4
            let refR = referenceBytes[offset]
            let refG = referenceBytes[offset + 1]
            let refB = referenceBytes[offset + 2]
            let refA = referenceBytes[offset + 3]
            let outR = outputBytes[offset]
            let outG = outputBytes[offset + 1]
            let outB = outputBytes[offset + 2]
            let outA = outputBytes[offset + 3]
            if abs(Int(refR) - Int(outR)) > Int(tolerance) ||
               abs(Int(refG) - Int(outG)) > Int(tolerance) ||
               abs(Int(refB) - Int(outB)) > Int(tolerance) ||
               abs(Int(refA) - Int(outA)) > Int(tolerance) {
                differences += 1
            }
        }
        let identical = differences == 0
        let differencePercentage = Double(differences) / Double(totalPixels)
        return ImageComparisonResult(
            identical: identical,
            pixelDifferences: differences,
            totalPixels: totalPixels,
            differencePercentage: differencePercentage
        )
    } catch {
        print("[ERROR] Failed to load reference image at: \(referenceImagePath.path) - \(error)")
        throw TestHarnessError.referenceImageLoadFailed
    }
}
    
    /// Helper function to compare two arrays for equality
    private func arraysEqual<T: Equatable>(_ lhs: [T], _ rhs: [T]) -> Bool {
        return lhs.count == rhs.count && lhs.elementsEqual(rhs)
    }

}

/// Errors that can occur during test harness operations
public enum TestHarnessError: Error, LocalizedError {
    case invalidFramebufferSize
    case colorSpaceCreationFailed
    case dataProviderCreationFailed
    case imageCreationFailed
    case destinationCreationFailed
    case imageSaveFailed
    case referenceImageLoadFailed
    case referenceDimensionMismatch
    case contextCreationFailed
    case pixelDataExtractionFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidFramebufferSize:
            return "Framebuffer size is not 160x144"
        case .colorSpaceCreationFailed:
            return "Failed to create color space"
        case .dataProviderCreationFailed:
            return "Failed to create data provider"
        case .imageCreationFailed:
            return "Failed to create CGImage"
        case .destinationCreationFailed:
            return "Failed to create image destination"
        case .imageSaveFailed:
            return "Failed to save image"
        case .referenceImageLoadFailed:
            return "Failed to load reference image"
        case .referenceDimensionMismatch:
            return "Reference image dimensions do not match GameBoy resolution (160x144)"
        case .contextCreationFailed:
            return "Failed to create graphics context"
        case .pixelDataExtractionFailed:
            return "Failed to extract pixel data from reference image"
        }
    }
}
