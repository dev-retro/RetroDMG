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
        
        if !memory.bootromLoaded {
            registers.write(register: .A, value: 0x01)
            registers.write(register: .B, value: 0x00)
            registers.write(register: .C, value: 0x13)
            registers.write(register: .D, value: 0x00)
            registers.write(register: .E, value: 0xD8)
            registers.write(register: .F, value: 0xB0)
            registers.write(register: .H, value: 0x01)
            registers.write(register: .L, value: 0x4D)

            registers.write(register: .PC, value: 0x0100)
            registers.write(register: .SP, value: 0xFFFE)
        }
    }
    
    mutating func tick() {
        cycles = 0 //TODO: remove once cycles are needed
        
        print("A: \(registers.read(register: .A).hex) F: \(registers.read(register: .F).hex) B: \(registers.read(register: .B).hex) C: \(registers.read(register: .C).hex) D: \(registers.read(register: .D).hex) E: \(registers.read(register: .E).hex) H: \(registers.read(register: .H).hex) L: \(registers.read(register: .L).hex) SP: \(registers.read(register: .SP).hex) PC: 00:\(registers.read(register: .PC).hex) (\(memory.read(location: registers.read(register: .PC)).hex) \(memory.read(location: registers.read(register: .PC)+1).hex) \(memory.read(location: registers.read(register: .PC)+2).hex) \(memory.read(location: registers.read(register: .PC)+3).hex))")
        
        
        
        let opCode = returnAndIncrement(indirect: .PC)
        
        switch opCode {
        case 0x00: //NOP
            cycles += 4
        case 0x01:
            loadFromMemory(to: .BC)
        case 0x02:
            load(indirect: .BC, register: .A)
        case 0x04:
            increment(register: .B)
        case 0x05:
            decrement(register: .B)
        case 0x06:
            load(from: .PC, to: .B)
        case 0x0A:
            load(register: .A, indirect: .BC)
        case 0x0C:
            increment(register: .C)
        case 0x0D:
            decrement(register: .C)
        case 0x0E:
            load(from: .PC, to: .C)
        case 0x11:
            loadFromMemory(to: .DE)
        case 0x12:
            load(indirect: .DE, register: .A)
        case 0x14:
            increment(register: .D)
        case 0x15:
            decrement(register: .D)
        case 0x16:
            load(from: .PC, to: .D)
        case 0x18:
            jump(type: .memorySigned8Bit)
        case 0x1A:
            load(register: .A, indirect: .DE)
        case 0x1C:
            increment(register: .E)
        case 0x1D:
            decrement(register: .E)
        case 0x1E:
            load(from: .PC, to: .E)
        case 0x20:
            jumpIfNot(flag: .Zero)
        case 0x21:
            loadFromMemory(to: .HL)
        case 0x22:
            load(indirect: .HL, register: .A)
            increment(register: .HL)
        case 0x24:
            increment(register: .H)
        case 0x25:
            decrement(register: .H)
        case 0x26:
            load(from: .PC, to: .H)
        case 0x2A:
            load(register: .A, indirect: .HL)
            increment(register: .HL)
        case 0x2C:
            increment(register: .L)
        case 0x2D:
            decrement(register: .L)
        case 0x2E:
            load(from: .PC, to: .L)
        case 0x31:
            loadFromMemory(to: .SP)
        case 0x32:
            load(indirect: .HL, register: .A)
            decrement(register: .HL)
        case 0x34:
            increment(indirect: .HL)
        case 0x36:
            load(indirect: .HL)
        case 0x3E:
            load(from: .PC, to: .A)
        case 0x3A:
            load(register: .A, indirect: .HL)
            decrement(register: .HL)
        case 0x3C:
            increment(register: .A)
        case 0x3D:
            decrement(register: .A)
        case 0x40:
            load(from: .B, to: .B)
        case 0x41:
            load(from: .C, to: .B)
        case 0x42:
            load(from: .D, to: .B)
        case 0x43:
            load(from: .E, to: .B)
        case 0x44:
            load(from: .H, to: .B)
        case 0x45:
            load(from: .L, to: .B)
        case 0x46:
            load(register: .B, indirect: .HL)
        case 0x47:
            load(from: .A, to: .B)
        case 0x48:
            load(from: .B, to: .C)
        case 0x49:
            load(from: .C, to: .C)
        case 0x4A:
            load(from: .D, to: .C)
        case 0x4B:
            load(from: .E, to: .C)
        case 0x4C:
            load(from: .H, to: .C)
        case 0x4D:
            load(from: .L, to: .C)
        case 0x4E:
            load(register: .C, indirect: .HL)
        case 0x4F:
            load(from: .A, to: .C)
        case 0x50:
            load(from: .B, to: .D)
        case 0x51:
            load(from: .C, to: .D)
        case 0x52:
            load(from: .D, to: .D)
        case 0x53:
            load(from: .E, to: .D)
        case 0x54:
            load(from: .H, to: .D)
        case 0x55:
            load(from: .L, to: .D)
        case 0x56:
            load(register: .D, indirect: .HL)
        case 0x57:
            load(from: .A, to: .D)
        case 0x58:
            load(from: .B, to: .E)
        case 0x59:
            load(from: .C, to: .E)
        case 0x5A:
            load(from: .D, to: .E)
        case 0x5B:
            load(from: .E, to: .E)
        case 0x5C:
            load(from: .H, to: .E)
        case 0x5D:
            load(from: .L, to: .E)
        case 0x5E:
            load(register: .E, indirect: .HL)
        case 0x5F:
            load(from: .A, to: .E)
        case 0x60:
            load(from: .B, to: .H)
        case 0x61:
            load(from: .C, to: .H)
        case 0x62:
            load(from: .D, to: .H)
        case 0x63:
            load(from: .E, to: .H)
        case 0x64:
            load(from: .H, to: .H)
        case 0x65:
            load(from: .L, to: .H)
        case 0x66:
            load(register: .H, indirect: .HL)
        case 0x67:
            load(from: .A, to: .H)
        case 0x68:
            load(from: .B, to: .L)
        case 0x69:
            load(from: .C, to: .L)
        case 0x6A:
            load(from: .D, to: .L)
        case 0x6B:
            load(from: .E, to: .L)
        case 0x6C:
            load(from: .H, to: .L)
        case 0x6D:
            load(from: .L, to: .L)
        case 0x6E:
            load(register: .L, indirect: .HL)
        case 0x6F:
            load(from: .A, to: .L)
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
            load(from: .B, to: .A)
        case 0x79:
            load(from: .C, to: .A)
        case 0x7A:
            load(from: .D, to: .A)
        case 0x7B:
            load(from: .E, to: .A)
        case 0x7C:
            load(from: .H, to: .A)
        case 0x7D:
            load(from: .L, to: .A)
        case 0x7E:
            load(register: .A, indirect: .HL)
        case 0x7F:
            load(from: .A, to: .A)
        case 0xC1:
            pop(register: .BC)
        case 0xC3:
            jump(type: .memoryUnsigned16Bit)
        case 0xC5:
            push(register: .BC)
        case 0xC9:
            ret()
        case 0xCD:
            call()
        case 0xD1:
            pop(register: .DE)
        case 0xD5:
            push(register: .DE)
        case 0xE0:
            loadToMemory(from: .A, masked: true)
        case 0xE1:
            pop(register: .HL)
        case 0xE5:
            push(register: .HL)
        case 0xEA:
            loadToMemory(from: .A)
        case 0xF1:
            pop(register: .AF)
        case 0xF3:
            set(ime: false)
        case 0xF5:
            push(register: .AF)
        default:
            fatalError("opCode 0x\(opCode.hex) not supported")
        }
    }
    
    mutating func returnAndIncrement(indirect register: RegisterType16) -> UInt8 {
        var regValue = registers.read(register: register)
        let value = memory.read(location: regValue)
        regValue += 1
        registers.write(register: register, value: regValue)
        
        return value
    }
    
    mutating func increment(register: RegisterType8) {
        var registerValue = registers.read(register: register)
        var value = registerValue.addingReportingOverflow(1)
        registers.write(register: register, value: value.partialValue)
        
        registers.write(flag: .Zero, set: value.partialValue == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: (registerValue & 0xF) + (1 & 0xF) > 0xF)
        
    }
    
    mutating func increment(register: RegisterType16) {
        var value = registers.read(register: register)
        
        registers.write(register: register, value: value.addingReportingOverflow(1).partialValue)
    }
    
    mutating func increment(indirect register: RegisterType16) {
        var registerValue = registers.read(register: register)
        var value = memory.read(location: registerValue)
        value += 1
        memory.write(location: registerValue, value: value)
        
        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: (registerValue & 0xF) + (1 & 0xF) > 0xF)
    }
    
    mutating func decrement(register: RegisterType8) {
        var currentValue = registers.read(register: register)
        var newValue = currentValue.subtractingReportingOverflow(1).partialValue
        registers.write(register: register, value: newValue)
        
        registers.write(flag: .Zero, set: newValue == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .HalfCarry, set: Int8(currentValue & 0xF) - Int8(1 & 0xF) < 0)
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
        let value = returnAndIncrement(indirect: fromRegister)
        registers.write(register: toRegister, value: value)
        cycles += 8
    }
    
    mutating func load(indirect register: RegisterType16) {
        let value = returnAndIncrement(indirect: .PC)
            memory.write(location: registers.read(register: register), value: value)
            cycles += 12
    }
    
    mutating func loadFromMemory(to register: RegisterType16) {
        let lsb = returnAndIncrement(indirect: .PC)
        let msb = returnAndIncrement(indirect: .PC)
        let value = UInt16(msb) << 8 | UInt16(lsb);
        
        registers.write(register: register, value: value)
        
        cycles += 12
    }
    
    mutating func loadToMemory(from register: RegisterType8, masked: Bool = false) {
        let lsb = returnAndIncrement(indirect: .PC)
        let msb = masked ? 0xFF : returnAndIncrement(indirect: .PC)
        
        let location = UInt16(msb) << 8 | UInt16(lsb);

        memory.write(location: location, value: registers.read(register: register))
        
        cycles += masked ? 12 : 16;
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
    
    mutating func jump(type: JumpType) {
        switch type {
        case .memorySigned8Bit:
            let address = Int8(returnAndIncrement(indirect: .PC))
            let address16Bit = UInt16(address)

            registers.write(register: .PC, value: registers.read(register: .PC).addingReportingOverflow(address16Bit).partialValue)

            cycles += 12
        case .memoryUnsigned16Bit:
            let lsb = returnAndIncrement(indirect: .PC)
            let msb = returnAndIncrement(indirect: .PC)
            let value = UInt16(msb) << 8 | UInt16(lsb);
            
            registers.write(register: .PC, value: value)
            
            cycles += 16
        default:
            fatalError("jump type not supported")
        }
    }
    
    mutating func jumpIfNot(flag: FlagType) {
        let address_raw = Int8(truncatingIfNeeded: returnAndIncrement(indirect: .PC))
        let address = Int16(address_raw)
        
        
        if !registers.read(flag: flag) {
            registers.write(register: .PC, value: UInt16(Int16(registers.read(register: .PC)) + address))
            cycles += 12
        } else {
            cycles += 8
        }
        
    }
    
    mutating func set(ime: Bool) {
        registers.write(ime: ime)
        cycles += 4
        state = .Running
    }
    
    mutating func call() {
        let lsb = returnAndIncrement(indirect: .PC)
        let msb = returnAndIncrement(indirect: .PC)
        let value = UInt16(msb) << 8 | UInt16(lsb);
        
        let pc = registers.read(register: .PC)
        let pcMsb = UInt8(pc >> 8)
        let pcLsb = UInt8(truncatingIfNeeded: pc)

        decrement(register: .SP)
        memory.write(location: registers.read(register: .SP), value: pcMsb)
        decrement(register: .SP)
        memory.write(location: registers.read(register: .SP), value: pcLsb)
        
        registers.write(register: .PC, value: value)

        self.cycles += 24;
    }
    
    mutating func ret() {
        let lsb = returnAndIncrement(indirect: .SP)
        let msb = returnAndIncrement(indirect: .SP)

        let value = UInt16(msb) << 8 | UInt16(lsb);

        registers.write(register: .PC, value: value)

        cycles += 16
    }
    
    mutating func push(register: RegisterType16) {
        let value = registers.read(register: register)
        decrement(register: .SP)
        memory.write(location: registers.read(register: .SP), value: UInt8(value >> 8))
        decrement(register: .SP)
        memory.write(location: registers.read(register: .SP), value: UInt8(truncatingIfNeeded: value))

        cycles += 16
    }
    
    mutating func pop(register: RegisterType16) {
        let lsb = returnAndIncrement(indirect: .SP)
        let msb = returnAndIncrement(indirect: .SP)
        let value = UInt16(msb) << 8 | UInt16(lsb);
        
        registers.write(register: register, value: value)
        
        cycles += 12
    }
}

enum JumpType {
   case memorySigned8Bit, memoryUnsigned16Bit
}
