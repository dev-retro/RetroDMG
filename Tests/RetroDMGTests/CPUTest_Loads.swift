import Testing
import Foundation
@testable import RetroDMG

@Suite("CPU Load Operations")
struct CPUTestLoads {
    // Load register-to-register operations: 40-7F (except 76 which is HALT)
    static let loadRegisterOpcodes = Array(0x40...0x7F).map { String(format: "%02x", $0) }.filter { $0 != "76" }
    
    // Load immediate operations: 06, 0E, 16, 1E, 26, 2E, 36, 3E, 01, 11, 21, 31
    static let loadImmediateOpcodes = ["06", "0e", "16", "1e", "26", "2e", "36", "3e", "01", "11", "21", "31"]
    
    // Load indirect operations: 0A, 1A, 2A, 3A, 02, 12, 22, 32, EA, FA, E0, F0, E2, F2
    static let loadIndirectOpcodes = ["0a", "1a", "2a", "3a", "02", "12", "22", "32", "ea", "fa", "e0", "f0", "e2", "f2"]
    
    // Load 16-bit operations: 08, F8, F9
    static let load16BitOpcodes = ["08", "f8", "f9"]
    
    static let allLoadOpcodes = loadRegisterOpcodes + loadImmediateOpcodes + loadIndirectOpcodes + load16BitOpcodes
    
    static func tests() throws -> [CPUJsonTest] {
        return try CPUOpcodeTestSupport.testFiles().filter { test in
            let opcode = test.name.split(separator: " ").prefix(1).joined(separator: " ").lowercased()
            return allLoadOpcodes.contains(opcode)
        }
    }

    @Test(arguments: try tests())
    func loadOperation(_ test: CPUJsonTest) {
        let cpu = CPU()
        cpu.bus.debug = true
        cpu.registers.a = test.initial.a
        cpu.registers.b = test.initial.b
        cpu.registers.c = test.initial.c
        cpu.registers.d = test.initial.d
        cpu.registers.e = test.initial.e
        cpu.registers.f = test.initial.f
        cpu.registers.h = test.initial.h
        cpu.registers.l = test.initial.l
        cpu.registers.pc = test.initial.pc
        cpu.registers.sp = test.initial.sp
        
        for memory in test.initial.ram {
            cpu.bus.write(location: memory[0], value: UInt8(truncatingIfNeeded: memory[1]))
        }
        
        var cycleCount = test.cycles
        while cycleCount > 0 {
            let removeCycles = cpu.tick()
            cycleCount = cycleCount - (Int(removeCycles) / 4)
        }
        
        for memory in test.final.ram {
            let value = cpu.bus.read(location: memory[0])
            #expect(value == UInt8(truncatingIfNeeded: memory[1]))
        }
        
        #expect(cpu.registers.a == test.final.a)
        #expect(cpu.registers.b == test.final.b)
        #expect(cpu.registers.c == test.final.c)
        #expect(cpu.registers.d == test.final.d)
        #expect(cpu.registers.e == test.final.e)
        #expect(cpu.registers.f == test.final.f)
        #expect(cpu.registers.h == test.final.h)
        #expect(cpu.registers.l == test.final.l)
        #expect(cpu.registers.pc == test.final.pc)
        #expect(cpu.registers.sp == test.final.sp)
    }
}