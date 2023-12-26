//
//  CPU.swift
//
//
//  Created by Glenn Hevey on 23/12/2023.
//

import Foundation

enum CPUState {
case Halted, Running
}

struct CPU {
    var registers: Registers
    var cycles: Int32
    var state: CPUState
    var memory: Memory
    
    init() {
        registers = Registers()
        cycles = 0
        state = .Running
        memory = Memory()
    }
    
    mutating func tick() {
        cycles = 0 //TODO: remove once cycles are needed
        
        let opCode = increment(register: .PC)
        
        switch opCode {
        case 0x00: //NOP
            cycles += 4
        case 0x02:
            load(indirect: .BC, register: .A)
        case 0x06:
            load(from: .PC, to: .B)
        case 0x0A:
            load(register: .A, indirect: .BC)
        case 0x0E:
            load(from: .PC, to: .C)
        case 0x12:
            load(indirect: .DE, register: .A)
        case 0x16:
            load(from: .PC, to: .D)
        case 0x1A:
            load(register: .A, indirect: .DE)
        case 0x1E:
            load(from: .PC, to: .E)
        case 0x22:
            load(indirect: .HL, register: .A)
            _ = increment(register: .HL)
        case 0x26:
            load(from: .PC, to: .H)
        case 0x2A:
            _ = increment(register: .HL)
            load(register: .A, indirect: .HL)
        case 0x2E:
            load(from: .PC, to: .L)
        case 0x32:
            load(indirect: .HL, register: .A)
            _ = decrement(register: .HL)
        case 0x36:
            load(indirect: .HL)
        case 0x3E:
            load(from: .PC, to: .A)
        case 0x3A:
            _ = decrement(register: .HL)
            load(register: .A, indirect: .HL)
        case 0x40:
            load(from: .B, to: .B)
        case 0x41:
            load(from: .B, to: .C)
        case 0x42:
            load(from: .B, to: .D)
        case 0x43:
            load(from: .B, to: .E)
        case 0x44:
            load(from: .B, to: .H)
        case 0x45:
            load(from: .B, to: .L)
        case 0x46:
            load(register: .B, indirect: .HL)
        case 0x47:
            load(from: .B, to: .A)
        case 0x48:
            load(from: .C, to: .B)
        case 0x49:
            load(from: .C, to: .C)
        case 0x4A:
            load(from: .C, to: .D)
        case 0x4B:
            load(from: .C, to: .E)
        case 0x4C:
            load(from: .C, to: .H)
        case 0x4D:
            load(from: .C, to: .L)
        case 0x4E:
            load(register: .C, indirect: .HL)
        case 0x4F:
            load(from: .C, to: .A)
        case 0x50:
            load(from: .D, to: .B)
        case 0x51:
            load(from: .D, to: .C)
        case 0x52:
            load(from: .D, to: .D)
        case 0x53:
            load(from: .D, to: .E)
        case 0x54:
            load(from: .D, to: .H)
        case 0x55:
            load(from: .D, to: .L)
        case 0x56:
            load(register: .D, indirect: .HL)
        case 0x57:
            load(from: .D, to: .A)
        case 0x58:
            load(from: .E, to: .B)
        case 0x59:
            load(from: .E, to: .C)
        case 0x5A:
            load(from: .E, to: .D)
        case 0x5B:
            load(from: .E, to: .E)
        case 0x5C:
            load(from: .E, to: .H)
        case 0x5D:
            load(from: .E, to: .L)
        case 0x5E:
            load(register: .E, indirect: .HL)
        case 0x5F:
            load(from: .E, to: .A)
        case 0x60:
            load(from: .H, to: .B)
        case 0x61:
            load(from: .H, to: .C)
        case 0x62:
            load(from: .H, to: .D)
        case 0x63:
            load(from: .H, to: .E)
        case 0x64:
            load(from: .H, to: .H)
        case 0x65:
            load(from: .H, to: .L)
        case 0x66:
            load(register: .H, indirect: .HL)
        case 0x67:
            load(from: .H, to: .A)
        case 0x68:
            load(from: .L, to: .B)
        case 0x69:
            load(from: .L, to: .C)
        case 0x6A:
            load(from: .L, to: .D)
        case 0x6B:
            load(from: .L, to: .E)
        case 0x6C:
            load(from: .L, to: .H)
        case 0x6D:
            load(from: .L, to: .L)
        case 0x6E:
            load(register: .L, indirect: .HL)
        case 0x6F:
            load(from: .L, to: .A)
        case 0x70:
            load(indirect: .HL, register: .B)
        case 0x71:
            load(indirect: .HL, register: .C)
        case 0x72:
            load(indirect: .HL, register: .D)
        case 0x73:
            load(indirect: .HL, register: .E)
        case 0x74:
            load(indirect: .HL, register: .H)
        case 0x75:
            load(indirect: .HL, register: .L)
        case 0x77:
            load(indirect: .HL, register: .A)
        case 0x78:
            load(from: .A, to: .B)
        case 0x79:
            load(from: .A, to: .C)
        case 0x7A:
            load(from: .A, to: .D)
        case 0x7B:
            load(from: .A, to: .E)
        case 0x7C:
            load(from: .A, to: .H)
        case 0x7D:
            load(from: .A, to: .L)
        case 0x7E:
            load(register: .A, indirect: .HL)
        case 0x7F:
            load(from: .A, to: .A)
        default:
            fatalError("opCode \(opCode) not supported")
        }
    }
    
    mutating func increment(register: RegisterType16) -> UInt8 {
        var regValue = registers.read(register: register)
        let value = memory.read(location: regValue)
        regValue += 1
        registers.write(register: register, value: regValue)
        
        return value
    }
    
    mutating func decrement(register: RegisterType16) -> UInt8 {
        var regValue = registers.read(register: register)
        let value = memory.read(location: regValue)
        regValue -= 1
        registers.write(register: register, value: regValue)
        
        return value
    }
    
    mutating func load(from fromRegister: RegisterType8, to toRegister: RegisterType8) {
        registers.write(register: toRegister, value: registers.read(register: fromRegister))
        cycles += 4
    }
    
    mutating func load(register: RegisterType8, indirect: RegisterType16) {
        registers.write(register: register, value: memory.read(location: registers.read(register: indirect)))
        cycles += 8
    }
    
    mutating func load(indirect: RegisterType16, register: RegisterType8) {
        memory.write(location: registers.read(register: indirect), value: registers.read(register: register))
        cycles += 8
    }
    
    mutating func load(from fromRegister: RegisterType16, to toRegister: RegisterType8) {
        let value = increment(register: fromRegister)
        registers.write(register: toRegister, value: value)
        cycles += 8
    }
    
    mutating func load(indirect register: RegisterType16) {
        let value = increment(register: .PC)
            memory.write(location: registers.read(register: register), value: value)
            cycles += 12
    }
    
//    mutating func load(indirect from: RegisterType8?) {
//        let lsb = increment(register: .PC)
//        var cycleCount: Int32 = 12
//        if from != nil {
//            let lsb = registers.read(register: from!)
//            cycleCount = 8
//        }
//        let msb = 0xFF
//        let location = UInt16(lsb << 8) | UInt16(msb)
//        
//        memory.write(location: location, value: UInt8)
//        
//        cycles += cycleCount
//    }
}
