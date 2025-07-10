import Testing
import Foundation
@testable import RetroDMG

@Suite("CPU Logical Operations")
struct CPUTestLogical {
    // AND operations: A0-A7, E6
    static let andOpcodes = ["a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "e6"]
    
    // XOR operations: A8-AF, EE
    static let xorOpcodes = ["a8", "a9", "aa", "ab", "ac", "ad", "ae", "af", "ee"]
    
    // OR operations: B0-B7, F6
    static let orOpcodes = ["b0", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "f6"]
    
    static let allLogicalOpcodes = andOpcodes + xorOpcodes + orOpcodes
    
    static func tests() throws -> [CPUJsonTest] {
        return try CPUOpcodeTestSupport.testFiles().filter { test in
            let opcode = test.name.split(separator: " ").prefix(1).joined(separator: " ").lowercased()
            return allLogicalOpcodes.contains(opcode)
        }
    }

    @Test(arguments: try tests())
    func logicalOperation(_ test: CPUJsonTest) {
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