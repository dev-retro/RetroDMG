import Testing
import Foundation
@testable import RetroDMG

@Suite("CPU Jump and Branch Operations")
struct CPUTestJumps {
    // Jump operations: C3, E9, C2, CA, D2, DA, CC, D4, DC, C4
    static let jumpOpcodes = ["c3", "e9", "c2", "ca", "d2", "da", "cc", "d4", "dc", "c4"]
    
    // Relative jump operations: 18, 20, 28, 30, 38
    static let relativeJumpOpcodes = ["18", "20", "28", "30", "38"]
    
    // Call operations: CD, C4, CC, D4, DC
    static let callOpcodes = ["cd", "c4", "cc", "d4", "dc"]
    
    // Return operations: C9, C0, C8, D0, D8
    static let returnOpcodes = ["c9", "c0", "c8", "d0", "d8"]
    
    // Restart operations: C7, CF, D7, DF, E7, EF, F7, FF
    static let restartOpcodes = ["c7", "cf", "d7", "df", "e7", "ef", "f7", "ff"]
    
    static let allJumpOpcodes = jumpOpcodes + relativeJumpOpcodes + callOpcodes + returnOpcodes + restartOpcodes
    
    static func tests() throws -> [CPUJsonTest] {
        return try CPUOpcodeTestSupport.testFiles().filter { test in
            let opcode = test.name.split(separator: " ").prefix(1).joined(separator: " ").lowercased()
            return allJumpOpcodes.contains(opcode)
        }
    }

    @Test(arguments: try tests())
    func jumpOperation(_ test: CPUJsonTest) {
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
