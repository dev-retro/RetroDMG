import Testing
import Foundation
@testable import RetroDMG

@Suite("CPU Tests")
struct CPUTests {

    static func testFiles() throws -> [CPUJsonTest] {
        let testFileNames = [
            //       "01", "02", "03", "04", "05", "06", "07", "08", "09", "0a", "0b", "0c", "0d", "0e", "0f",
            //       "11", "12", "13", "14", "15", "16", "17", "18", "19", "1a", "1b", "1c", "1d", "1e", "1f",
            // "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "2a", "2b", "2c", "2d", "2e", "2f",
            // "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "3a", "3b", "3c", "3d", "3e", "3f",
            // "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "4a", "4b", "4c", "4d", "4e", "4f",
            // "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "5a", "5b", "5c", "5d", "5e", "5f",
            // "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "6a", "6b", "6c", "6d", "6e", "6f",
            // "70", "71", "72", "73", "74", "75",       "77", "78", "79", "7a", "7b", "7c", "7d", "7e", "7f",
            // "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "8a", "8b", "8c", "8d", "8e", "8f",
            // "90", "91", "92", "93", "94", "95", "96", "97", "98", "99", "9a", "9b", "9c", "9d", "9e", "9f",
            // "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "aa", "ab", "ac", "ad", "ae", "af",
            // "b0", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "ba", "bb", "bc", "bd", "be", "bf",
            // "c0", "c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", "c9", "ca",       "cc", "cd", "ce", "cf",
            // "d0", "d1", "d2",       "d4", "d5", "d6", "d7", "d8", "d9", "da",       "dc",       "de", "df", 
            // "e0", "e1", "e2",             "e5", "e6", "e7", "e8", "e9", "ea",                   "de", "df",  
            // "f0", "f1", "f2", "f3",       "f5", "f6", "f7", "f8", "f9", "fa", "fb",             "fe", "ff",

            // "cb 00", "cb 01", "cb 02", "cb 03", "cb 04", "cb 05", "cb 06", "cb 07", "cb 08", "cb 09", "cb 0a", "cb 0b", "cb 0c", "cb 0d", "cb 0e", "cb 0f",
            // "cb 10", "cb 11", "cb 12", "cb 13", "cb 14", "cb 15", "cb 16", "cb 17", "cb 18", "cb 19", "cb 1a", "cb 1b", "cb 1c", "cb 1d", "cb 1e", "cb 1f",
            // "cb 20", "cb 21", "cb 22", "cb 23", "cb 24", "cb 25", "cb 26", "cb 27", "cb 28", "cb 29", "cb 2a", "cb 2b", "cb 2c", "cb 2d", "cb 2e", "cb 2f",
            // "cb 30", "cb 31", "cb 32", "cb 33", "cb 34", "cb 35", "cb 36", "cb 37", "cb 38", "cb 39", "cb 3a", "cb 3b", "cb 3c", "cb 3d", "cb 3e", "cb 3f",
            // "cb 40", "cb 41", "cb 42", "cb 43", "cb 44", "cb 45", "cb 46", "cb 47", "cb 48", "cb 49", "cb 4a", "cb 4b", "cb 4c", "cb 4d", "cb 4e", "cb 4f",
            // "cb 50", "cb 51", "cb 52", "cb 53", "cb 54", "cb 55", "cb 56", "cb 57", "cb 58", "cb 59", "cb 5a", "cb 5b", "cb 5c", "cb 5d", "cb 5e", "cb 5f",
            // "cb 60", "cb 61", "cb 62", "cb 63", "cb 64", "cb 65", "cb 66", "cb 67", "cb 68", "cb 69", "cb 6a", "cb 6b", "cb 6c", "cb 6d", "cb 6e", "cb 6f",
            // "cb 70", "cb 71", "cb 72", "cb 73", "cb 74", "cb 75", "cb 76", "cb 77", "cb 78", "cb 79", "cb 7a", "cb 7b", "cb 7c", "cb 7d", "cb 7e", "cb 7f",
            // "cb 80", "cb 81", "cb 82", "cb 83", "cb 84", "cb 85", "cb 86", "cb 87", "cb 88", "cb 89", "cb 8a", "cb 8b", "cb 8c", "cb 8d", "cb 8e", "cb 8f",
            // "cb 90", "cb 91", "cb 92", "cb 93", "cb 94", "cb 95", "cb 96", "cb 97", "cb 98", "cb 99", "cb 9a", "cb 9b", "cb 9c", "cb 9d", "cb 9e", "cb 9f",
            // "cb a0", "cb a1", "cb a2", "cb a3", "cb a4", "cb a5", "cb a6", "cb a7", "cb a8", "cb a9", "cb aa", "cb ab", "cb ac", "cb ad", "cb ae", "cb af",
            // "cb b0", "cb b1", "cb b2", "cb b3", "cb b4", "cb b5", "cb b6", "cb b7", "cb b8", "cb b9", "cb ba", "cb bb", "cb bc", "cb bd", "cb be", "cb bf",
            // "cb c0", "cb c1", "cb c2", "cb c3", "cb c4", "cb c5", "cb c6", "cb c7", "cb c8", "cb c9", "cb ca", "cb cb", "cb cc", "cb cd", "cb ce", "cb cf",
            // "cb d0", "cb d1", "cb d2", "cb d3", "cb d4", "cb d5", "cb d6", "cb d7", "cb d8", "cb d9", "cb da", "cb db", "cb dc", "cb dd", "cb de", "cb df",
            // "cb e0", "cb e1", "cb e2", "cb e3", "cb e4", "cb e5", "cb e6", "cb e7", "cb e8", "cb e9", "cb ea", "cb eb", "cb ec", "cb ed", "cb ee", "cb ef",
            "cb f0", "cb f1", "cb f2", "cb f3", "cb f4", "cb f5", "cb f6", "cb f7", "cb f8", "cb f9", "cb fa", "cb fb", "cb fc", "cb fd", "cb fe", "cb ff",
            ]
        var testFiles = [CPUJsonTest]()
        for test in testFileNames { 
            let file = try Data(contentsOf: Bundle.module.url(forResource: test, withExtension: "json")!)
            testFiles.append(contentsOf: try JSONDecoder().decode([CPUJsonTest].self, from: file))
        }
        return testFiles
    }
    
    @Test(arguments: try testFiles())
    func opCode(_ test: CPUJsonTest) {
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

struct CPUJsonTests: Codable {
    let tests: [CPUJsonTest]
}

struct CPUJsonTest: Codable {
    let name: String
    let initial: State
    let final: State
    let cycles: Int
    
    struct State: Codable {
        let a: UInt8
        let b: UInt8
        let c: UInt8
        let d: UInt8
        let e: UInt8
        let f: UInt8
        let h: UInt8
        let ie: UInt8?
        let ime: UInt8?
        let l: UInt8
        let pc: UInt16
        let ram: [[UInt16]]
        let sp: UInt16
    }
}

extension CPUJsonTest: CustomTestStringConvertible {
    var testDescription: String {
        "OpCode Test: \(name)"
    }
}
