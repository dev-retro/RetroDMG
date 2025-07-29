import Foundation
@testable import RetroDMG

// Quick APU register mask verification
let apu = APU()

print("APU Register Mask Verification:")
print("Expected vs Actual")

let testMasks: [(UInt16, UInt8, String)] = [
    (0xFF10, 0x80, "NR10"),
    (0xFF11, 0x3F, "NR11"), 
    (0xFF12, 0x00, "NR12"),
    (0xFF13, 0xFF, "NR13"),
    (0xFF14, 0xBF, "NR14"),
    (0xFF16, 0x3F, "NR21"),
    (0xFF17, 0x00, "NR22"),
    (0xFF18, 0xFF, "NR23"),
    (0xFF19, 0xBF, "NR24"),
    (0xFF1A, 0x7F, "NR30"),
    (0xFF1B, 0xFF, "NR31"),
    (0xFF1C, 0x9F, "NR32"),
    (0xFF1D, 0xFF, "NR33"),
    (0xFF1E, 0xBF, "NR34"),
    (0xFF20, 0xFF, "NR41"),
    (0xFF21, 0x00, "NR42"),
    (0xFF22, 0x00, "NR43"),
    (0xFF23, 0xBF, "NR44"),
    (0xFF24, 0x00, "NR50"),
    (0xFF25, 0x00, "NR51"),
    (0xFF26, 0x70, "NR52")
]

for (address, expectedMask, name) in testMasks {
    // Write 0x00 then read
    apu.writeRegister(address, value: 0x00)
    let read0 = apu.readRegister(address)
    
    // Write 0xFF then read
    apu.writeRegister(address, value: 0xFF)
    let readFF = apu.readRegister(address)
    
    let actualMask = read0
    let matches = (actualMask == expectedMask)
    
    print("\(name): Expected \(String(format: "$%02X", expectedMask)), Got \(String(format: "$%02X", actualMask)) \(matches ? "✅" : "❌")")
    
    if !matches {
        print("  Write 0x00 → Read \(String(format: "$%02X", read0))")
        print("  Write 0xFF → Read \(String(format: "$%02X", readFF))")
    }
}
