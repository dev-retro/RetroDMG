import Testing
import Foundation
@testable import RetroDMG

@Suite("CPU Bitwise Operations")
struct CPUTestBitwise {
    // Logical operations: A0-A7 (AND), A8-AF (XOR), B0-B7 (OR), E6 (AND #), EE (XOR #), F6 (OR #)
    static let logicalOpcodes = ["a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "aa", "ab", "ac", "ad", "ae", "af", "b0", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "e6", "ee", "f6"]
    
    // Rotate/shift operations: 07, 0F, 17, 1F (single register), CB-prefixed for all registers
    static let rotateShiftOpcodes = ["07", "0f", "17", "1f"]
    
    // CB-prefixed operations (handled separately due to volume)
    static let cbPrefixedOpcodes = ["cb"]
    
    static let allBitwiseOpcodes = logicalOpcodes + rotateShiftOpcodes + cbPrefixedOpcodes
    
    static func tests() throws -> [CPUJsonTest] {
        return try CPUOpcodeTestSupport.testFiles().filter { test in
            let opcode = test.name.split(separator: " ").prefix(1).joined(separator: " ").lowercased()
            return allBitwiseOpcodes.contains(opcode)
        }
    }

    @Test(arguments: try tests())
    func bitwiseOperation(_ test: CPUJsonTest) {
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