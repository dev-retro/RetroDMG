import Testing
import Foundation
@testable import RetroDMG

@Suite("CPU Arithmetic Operations")
struct CPUTestArithmetic {
    // ADD operations: 80-87, C6, 09, 19, 29, 39, E8
    static let addOpcodes = ["80", "81", "82", "83", "84", "85", "86", "87", "c6", "09", "19", "29", "39", "e8"]
    
    // ADC operations: 88-8F, CE
    static let adcOpcodes = ["88", "89", "8a", "8b", "8c", "8d", "8e", "8f", "ce"]
    
    // SUB operations: 90-97, D6
    static let subOpcodes = ["90", "91", "92", "93", "94", "95", "96", "97", "d6"]
    
    // SBC operations: 98-9F, DE
    static let sbcOpcodes = ["98", "99", "9a", "9b", "9c", "9d", "9e", "9f", "de"]
    
    // INC operations: 04, 0C, 14, 1C, 24, 2C, 34, 3C, 03, 13, 23, 33
    static let incOpcodes = ["04", "0c", "14", "1c", "24", "2c", "34", "3c", "03", "13", "23", "33"]
    
    // DEC operations: 05, 0D, 15, 1D, 25, 2D, 35, 3D, 0B, 1B, 2B, 3B
    static let decOpcodes = ["05", "0d", "15", "1d", "25", "2d", "35", "3d", "0b", "1b", "2b", "3b"]
    
    // Compare operations: B8-BF, FE
    static let compareOpcodes = ["b8", "b9", "ba", "bb", "bc", "bd", "be", "bf", "fe"]
    
    static let allArithmeticOpcodes = addOpcodes + adcOpcodes + subOpcodes + sbcOpcodes + incOpcodes + decOpcodes + compareOpcodes
    
    static func tests() throws -> [CPUJsonTest] {
        return try CPUOpcodeTestSupport.testFiles().filter { test in
            let opcode = test.name.split(separator: " ").prefix(1).joined(separator: " ").lowercased()
            return allArithmeticOpcodes.contains(opcode)
        }
    }

    @Test(arguments: try tests())
    func arithmeticOperation(_ test: CPUJsonTest) {
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
