import Testing
import Foundation
@testable import RetroDMG

@Suite("ROM Integration Tests")
struct TestROMIntegrationTests {
    init() {
        #if DEBUG
        print("[WARNING] ROM integration tests are not running in release mode. For accurate results, use 'swift test -c release'.")
        #endif
    }
    
    func getTestROMPath(romPath: String) -> URL? {
        let bundle = Bundle.module
        
        guard let url = bundle.url(forResource: romPath, withExtension: nil) else {
            print("ROM not found at path: \(romPath)")
            return nil
        }
        
        return url
    }
    
    @Test("Test ROM resource access")
    func testROMResourceAccess() throws {
        // Test that we can access a known test ROM
        let romPath = "test-roms/dmg-acid2/dmg-acid2.gb"
        let romURL = getTestROMPath(romPath: romPath)
        
        #expect(romURL != nil, "ROM should be accessible")
        
        if let url = romURL {
            let data = try Data(contentsOf: url)
            #expect(data.count > 0, "ROM should contain data")
            print("Successfully loaded ROM: \(romPath), size: \(data.count) bytes")
        }
    }

    @Test("Blargg CPU instruction test: framebuffer matches reference PNG")
    func testBlarggCPUInstrsFramebuffer() async throws {
        let romPath = "test-roms/blargg/cpu_instrs/cpu_instrs.gb"
        let referencePNGPath = "test-roms/blargg/cpu_instrs/cpu_instrs-dmg-cgb.png"

        // Locate ROM
        guard let romURL = Bundle.module.url(forResource: romPath, withExtension: nil) else {
            throw TestError.romNotFound("ROM not found: \(romPath)")
        }
        let romData = try Data(contentsOf: romURL)
        #expect(romData.count > 0, "ROM should contain data")

        // Locate reference PNG
        guard let referenceURL = Bundle.module.url(forResource: referencePNGPath, withExtension: nil) else {
            print("Reference PNG not found: \(referencePNGPath)")
            print("Please run the DownloadTestROMs.sh script to fetch all required test files.")
            throw TestError.referenceImageNotFound("Reference PNG missing: \(referencePNGPath)")
        }

        // Prepare output directory (relative to project)
        let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let outputDir = projectRoot.appendingPathComponent("TestOutputs/blargg-cpu-instrs-test")

        
        // Run the test harness
        let harness = TestHarness()
        let config = TestHarness.TestConfig(
            duration: 90, // Run for 90 seconds (adjust as needed)
            maxFrames: 100,
            outputDirectory: outputDir,
            referenceImagePath: referenceURL,
            testName: "blargg-cpu-instrs"
        )
        let result = await harness.runTest(romData: [UInt8](romData), config: config)

        // Save all captured frames to disk (if available)
        if result.capturedFramePath == nil {
            print("No frame was captured.")
        } else {
            print("Captured frame: \(result.capturedFramePath?.path ?? "None")")
        }

        // Print result summary
        print("Test finished: \(result.testName)")
        print("Execution time: \(result.executionTime)s")
        print("Output directory: \(outputDir.path)")
        if let comparison = result.comparisonResult {
            print("Image match: \(comparison.identical), Differences: \(comparison.pixelDifferences)/\(comparison.totalPixels) (\(comparison.percentageString))")
        }

        // Copy reference image to output directory for visual comparison
        if let referenceImagePath = result.referenceImagePath {
            let referenceURL = URL(fileURLWithPath: referenceImagePath.path)
            let destURL = outputDir.appendingPathComponent("reference-cpu-instrs.png")
            do {
                try FileManager.default.copyItem(at: referenceURL, to: destURL)
            } catch {
                print("Failed to copy reference image: \(error)")
            }
        }

        // Assert images match
        #expect(result.success, "Framebuffer output should match reference PNG")
    }

    enum TestError: Error {
        case romNotFound(String)
        case referenceImageNotFound(String)
    }

    @Test("DMG-ACID2 test: framebuffer matches reference PNG")
    func testDMGACID2Framebuffer() async throws {
        let romPath = "test-roms/dmg-acid2/dmg-acid2.gb"
        let referencePNGPath = "test-roms/dmg-acid2/dmg-acid2-dmg.png"

        // Locate ROM
        guard let romURL = Bundle.module.url(forResource: romPath, withExtension: nil) else {
            throw TestError.romNotFound("ROM not found: \(romPath)")
        }
        let romData = try Data(contentsOf: romURL)
        #expect(romData.count > 0, "ROM should contain data")

        // Locate reference PNG
        guard let referenceURL = Bundle.module.url(forResource: referencePNGPath, withExtension: nil) else {
            print("Reference PNG not found: \(referencePNGPath)")
            print("Please run the DownloadTestROMs.sh script to fetch all required test files.")
            throw TestError.referenceImageNotFound("Reference PNG missing: \(referencePNGPath)")
        }

        // Prepare output directory (relative to project)
        let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let outputDir = projectRoot.appendingPathComponent("TestOutputs/dmg-acid2-test")

        // Run the test harness
        let harness = TestHarness()
        let config = TestHarness.TestConfig(
            duration: 5, // Run for 5 seconds (adjust as needed)
            maxFrames: 100,
            outputDirectory: outputDir,
            referenceImagePath: referenceURL,
            testName: "dmg-acid2"
        )
        let result = await harness.runTest(romData: [UInt8](romData), config: config)

        // Save all captured frames to disk (if available)
        if result.capturedFramePath == nil {
            print("No frame was captured.")
        } else {
            print("Captured frame: \(result.capturedFramePath?.path ?? "None")")
        }

        // Print result summary
        print("Test finished: \(result.testName)")
        print("Execution time: \(result.executionTime)s")
        print("Output directory: \(outputDir.path)")
        if let comparison = result.comparisonResult {
            print("Image match: \(comparison.identical), Differences: \(comparison.pixelDifferences)/\(comparison.totalPixels) (\(comparison.percentageString))")
        }

        // Copy reference image to output directory for visual comparison
        if let referenceImagePath = result.referenceImagePath {
            let referenceURL = URL(fileURLWithPath: referenceImagePath.path)
            let destURL = outputDir.appendingPathComponent("reference-dmg-acid2.png")
            do {
                try FileManager.default.copyItem(at: referenceURL, to: destURL)
            } catch {
                print("Failed to copy reference image: \(error)")
            }
        }

        // Assert images match
        #expect(result.success, "Framebuffer output should match reference PNG")
    }
}
