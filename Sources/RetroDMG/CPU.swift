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
        
//        print("A: \(registers.read(register: .A).hex) F: \(registers.read(register: .F).hex) B: \(registers.read(register: .B).hex) C: \(registers.read(register: .C).hex) D: \(registers.read(register: .D).hex) E: \(registers.read(register: .E).hex) H: \(registers.read(register: .H).hex) L: \(registers.read(register: .L).hex) SP: \(registers.read(register: .SP).hex) PC: 00:\(registers.read(register: .PC).hex) (\(memory.read(location: registers.read(register: .PC)).hex) \(memory.read(location: registers.read(register: .PC)+1).hex) \(memory.read(location: registers.read(register: .PC)+2).hex) \(memory.read(location: registers.read(register: .PC)+3).hex))")
        
        
        let opCode = returnAndIncrement(indirect: .PC)
        
        switch opCode {
        case 0x00: //NOP
            cycles += 4
        case 0x01:
            loadFromMemory(to: .BC)
        case 0x02:
            load(indirect: .BC, register: .A)
        case 0x03:
            increment(register: .BC)
        case 0x04:
            increment(register: .B)
        case 0x05:
            decrement(register: .B)
        case 0x06:
            load(from: .PC, to: .B)
        //TODO: 0x07
        //TODO: 0x08
        case 0x09:
            add(register: .BC)
        case 0x0A:
            load(register: .A, indirect: .BC)
        //TODO: 0x0B
        case 0x0C:
            increment(register: .C)
        case 0x0D:
            decrement(register: .C)
        case 0x0E:
            load(from: .PC, to: .C)
        //TODO: 0x0F
        case 0x11:
            loadFromMemory(to: .DE)
        case 0x12:
            load(indirect: .DE, register: .A)
        case 0x13:
            increment(register: .DE)
        case 0x14:
            increment(register: .D)
        case 0x15:
            decrement(register: .D)
        case 0x16:
            load(from: .PC, to: .D)
        //TODO: 0x17
        case 0x18:
            jump(type: .memorySigned8Bit)
        case 0x19:
            add(register: .DE)
        case 0x1A:
            load(register: .A, indirect: .DE)
        //TODO: 0x1B
        case 0x1C:
            increment(register: .E)
        case 0x1D:
            decrement(register: .E)
        case 0x1E:
            load(from: .PC, to: .E)
        case 0x1F:
            rotateRight(register: .A, zeroDependant: false)
        case 0x20:
            jumpIfNot(flag: .Zero)
        case 0x21:
            loadFromMemory(to: .HL)
        case 0x22:
            load(indirect: .HL, register: .A)
            increment(register: .HL, partOfOtherOpCode: true)
        case 0x23:
            increment(register: .HL)
        case 0x24:
            increment(register: .H)
        case 0x25:
            decrement(register: .H)
        case 0x26:
            load(from: .PC, to: .H)
        //TODO: 0x27
        case 0x28:
            jumpIf(flag: .Zero)
        case 0x29:
            add(register: .HL)
        case 0x2A:
            load(register: .A, indirect: .HL)
            increment(register: .HL, partOfOtherOpCode: true)
        //TODO: 0x2B
        case 0x2C:
            increment(register: .L)
        case 0x2D:
            decrement(register: .L)
        case 0x2E:
            load(from: .PC, to: .L)
        //TODO: 0x2F
        case 0x30:
            jumpIfNot(flag: .Carry)
        case 0x31:
            loadFromMemory(to: .SP)
        case 0x32:
            load(indirect: .HL, register: .A)
            decrement(register: .HL)
        case 0x33:
            increment(register: .HL)
        case 0x34:
            increment(indirect: .HL)
        case 0x35:
            decrement(indirect: .HL)
        case 0x36:
            load(indirect: .HL)
        //TODO: 0x37
        case 0x38:
            jumpIf(flag: .Carry)
        case 0x39:
            add(register: .SP)
        case 0x3A:
            load(register: .A, indirect: .HL)
            decrement(register: .HL)
        //TODO: 0x3B
        case 0x3C:
            increment(register: .A)
        case 0x3D:
            decrement(register: .A)
        case 0x3E:
            load(from: .PC, to: .A)
        //TODO: 0x3F
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
        //TODO: 0x76
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
        //TODO: 0x80
        //TODO: 0x81
        //TODO: 0x82
        //TODO: 0x83
        //TODO: 0x84
        //TODO: 0x85
        //TODO: 0x86
        //TODO: 0x87
        //TODO: 0x88
        //TODO: 0x89
        //TODO: 0x8A
        //TODO: 0x8B
        //TODO: 0x8C
        //TODO: 0x8D
        //TODO: 0x8E
        //TODO: 0x8F
        //TODO: 0x90
        //TODO: 0x91
        //TODO: 0x92
        //TODO: 0x93
        //TODO: 0x94
        //TODO: 0x95
        //TODO: 0x96
        //TODO: 0x97
        //TODO: 0x98
        //TODO: 0x99
        //TODO: 0x9A
        //TODO: 0x9B
        //TODO: 0x9C
        //TODO: 0x9D
        //TODO: 0x9E
        //TODO: 0x9F
        //TODO: 0xA0
        //TODO: 0xA1
        //TODO: 0xA2
        //TODO: 0xA3
        //TODO: 0xA4
        //TODO: 0xA5
        //TODO: 0xA6
        //TODO: 0xA7
        case 0xA8:
            xor(register: .B)
        case 0xA9:
            xor(register: .C)
        case 0xAA:
            xor(register: .D)
        case 0xAB:
            xor(register: .E)
        case 0xAC:
            xor(register: .H)
        case 0xAD:
            xor(register: .L)
        case 0xAE:
            xor(indirect: .HL)
        case 0xAF:
            xor(register: .A)
        case 0xB0:
            or(register: .B)
        case 0xB1:
            or(register: .C)
        case 0xB2:
            or(register: .D)
        case 0xB3:
            or(register: .E)
        case 0xB4:
            or(register: .H)
        case 0xB5:
            or(register: .L)
        case 0xB6:
            or(indirect: .HL)
        case 0xB7:
            or(register: .A)
        //TODO: 0xB8
        //TODO: 0xB9
        //TODO: 0xBA
        //TODO: 0xBB
        //TODO: 0xBC
        //TODO: 0xBD
        //TODO: 0xBE
        //TODO: 0xBF
        case 0xC0:
            retIfNotSet(flag: .Zero)
        case 0xC1:
            pop(register: .BC)
        //TODO: 0xC2
        case 0xC3:
            jump(type: .memoryUnsigned16Bit)
        case 0xC4:
            callIfNot(flag: .Zero)
        case 0xC5:
            push(register: .BC)
        case 0xC6:
            add()
        //TODO: 0xC7
        case 0xC8:
            retIfSet(flag: .Zero)
        case 0xC9:
            ret()
        //TODO: 0xCA
        case 0xCB:
            extendedOpCodes()
        //TODO: 0xCC
        case 0xCD:
            call()
        case 0xCE:
            addWithCarry()
        //TODO: 0xCF
        case 0xD0:
            retIfNotSet(flag: .Carry)
        case 0xD1:
            pop(register: .DE)
        //TODO: 0xD2
        case 0xD3:
            return //Not Used
        //TODO: 0xD4
        case 0xD5:
            push(register: .DE)
        case 0xD6:
            sub()
        //TODO: 0xD7
        case 0xD8:
            retIfSet(flag: .Carry)
        //TODO: 0xD9
        //TODO: 0xDA
        case 0xDB:
            return //Not Used
        //TODO: 0xDC
        //TODO: 0xDE
        //TODO: 0xDF
        case 0xE0:
            loadToMemory(from: .A, masked: true)
        case 0xE1:
            pop(register: .HL)
        //TODO: 0xE2
        case 0xE3:
            return //Not Used
        case 0xE4:
            return //Not Used
        case 0xE5:
            push(register: .HL)
        case 0xE6:
            and()
        //TODO: 0xE7
        //TODO: 0xE8
        case 0xE9:
            jump(to: .HL)
        case 0xEA:
            loadToMemory(from: .A)
        case 0xEB:
            return //Not Used
        case 0xEC:
            return //Not Used
        case 0xED:
            return //Not Used
        case 0xEE:
            xor()
        //TODO: 0xEF
        case 0xF0:
            loadFromMemory(to: .A, masked: true)
        case 0xF1:
            pop(register: .AF)
        //TODO: 0xF2
        case 0xF3:
            set(ime: false)
        case 0xF4:
            return //Not Used
        case 0xF5:
            push(register: .AF)
        //TODO: 0xF6
        //TODO: 0xF7
        //TODO: 0xF8
        //TODO: 0xF9
        case 0xFA:
            loadFromMemory(to: .A, masked: false)
        //TODO: 0xFB
        case 0xFC:
            return //Not Used
        case 0xFD:
            return //Not Used
        case 0xFE:
            copy()
        //TODO: 0xFF
        default:
            fatalError("opCode 0x\(opCode.hex) not supported")
        }
    }
    
    mutating func extendedOpCodes() {
        let opCode = returnAndIncrement(indirect: .PC)
        
        switch opCode {
        //TODO: 0x00
        //TODO: 0x01
        //TODO: 0x02
        //TODO: 0x03
        //TODO: 0x04
        //TODO: 0x05
        //TODO: 0x06
        //TODO: 0x07
        //TODO: 0x08
        //TODO: 0x09
        //TODO: 0x0A
        //TODO: 0x0B
        //TODO: 0x0C
        //TODO: 0x0D
        //TODO: 0x0E
        //TODO: 0x0F
        //TODO: 0x10
        //TODO: 0x11
        //TODO: 0x12
        //TODO: 0x13
        //TODO: 0x14
        //TODO: 0x15
        //TODO: 0x16
        //TODO: 0x17
        case 0x18:
            rotateRight(register: .B)
        case 0x19:
            rotateRight(register: .C)
        case 0x1A:
            rotateRight(register: .D)
        case 0x1B:
            rotateRight(register: .E)
        case 0x1C:
            rotateRight(register: .H)
        case 0x1D:
            rotateRight(register: .L)
        case 0x1E:
            rotateRight(indirect: .HL)
        case 0x1F:
            rotateRight(register: .A)
        //TODO: 0x20
        //TODO: 0x21
        //TODO: 0x22
        //TODO: 0x23
        //TODO: 0x24
        //TODO: 0x25
        //TODO: 0x26
        //TODO: 0x27
        //TODO: 0x28
        //TODO: 0x29
        //TODO: 0x2A
        //TODO: 0x2B
        //TODO: 0x2C
        //TODO: 0x2D
        //TODO: 0x2E
        //TODO: 0x2F
        //TODO: 0x30
        //TODO: 0x31
        //TODO: 0x32
        //TODO: 0x33
        //TODO: 0x34
        //TODO: 0x35
        //TODO: 0x36
        //TODO: 0x37
        case 0x38:
            shiftRight(register: .B)
        case 0x39:
            shiftRight(register: .C)
        case 0x3A:
            shiftRight(register: .D)
        case 0x3B:
            shiftRight(register: .E)
        case 0x3C:
            shiftRight(register: .H)
        case 0x3D:
            shiftRight(register: .L)
        case 0x3E:
            shiftRight(indirect: .HL)
        case 0x3F:
            shiftRight(register: .A)
        //TODO: 0x40
        //TODO: 0x41
        //TODO: 0x42
        //TODO: 0x43
        //TODO: 0x44
        //TODO: 0x45
        //TODO: 0x46
        //TODO: 0x47
        //TODO: 0x48
        //TODO: 0x49
        //TODO: 0x4A
        //TODO: 0x4B
        //TODO: 0x4C
        //TODO: 0x4D
        //TODO: 0x4E
        //TODO: 0x4F
        //TODO: 0x50
        //TODO: 0x51
        //TODO: 0x52
        //TODO: 0x53
        //TODO: 0x54
        //TODO: 0x55
        //TODO: 0x56
        //TODO: 0x57
        //TODO: 0x58
        //TODO: 0x59
        //TODO: 0x5A
        //TODO: 0x5B
        //TODO: 0x5C
        //TODO: 0x5D
        //TODO: 0x5E
        //TODO: 0x5F
        //TODO: 0x60
        //TODO: 0x61
        //TODO: 0x62
        //TODO: 0x63
        //TODO: 0x64
        //TODO: 0x65
        //TODO: 0x66
        //TODO: 0x67
        //TODO: 0x68
        //TODO: 0x69
        //TODO: 0x6A
        //TODO: 0x6B
        //TODO: 0x6C
        //TODO: 0x6D
        //TODO: 0x6E
        //TODO: 0x6F
        //TODO: 0x70
        //TODO: 0x71
        //TODO: 0x72
        //TODO: 0x73
        //TODO: 0x74
        //TODO: 0x75
        //TODO: 0x76
        //TODO: 0x77
        //TODO: 0x78
        //TODO: 0x79
        //TODO: 0x7A
        //TODO: 0x7B
        //TODO: 0x7C
        //TODO: 0x7D
        //TODO: 0x7E
        //TODO: 0x7F
        //TODO: 0x80
        //TODO: 0x81
        //TODO: 0x82
        //TODO: 0x83
        //TODO: 0x84
        //TODO: 0x85
        //TODO: 0x86
        //TODO: 0x87
        //TODO: 0x88
        //TODO: 0x89
        //TODO: 0x8A
        //TODO: 0x8B
        //TODO: 0x8C
        //TODO: 0x8D
        //TODO: 0x8E
        //TODO: 0x8F
        //TODO: 0x90
        //TODO: 0x91
        //TODO: 0x92
        //TODO: 0x93
        //TODO: 0x94
        //TODO: 0x95
        //TODO: 0x96
        //TODO: 0x97
        //TODO: 0x98
        //TODO: 0x99
        //TODO: 0x9A
        //TODO: 0x9B
        //TODO: 0x9C
        //TODO: 0x9D
        //TODO: 0x9E
        //TODO: 0x9F
        //TODO: 0xA0
        //TODO: 0xA1
        //TODO: 0xA2
        //TODO: 0xA3
        //TODO: 0xA4
        //TODO: 0xA5
        //TODO: 0xA6
        //TODO: 0xA7
        //TODO: 0xA8
        //TODO: 0xA9
        //TODO: 0xAA
        //TODO: 0xAB
        //TODO: 0xAC
        //TODO: 0xAD
        //TODO: 0xAE
        //TODO: 0xAF
        //TODO: 0xB0
        //TODO: 0xB1
        //TODO: 0xB2
        //TODO: 0xB3
        //TODO: 0xB4
        //TODO: 0xB5
        //TODO: 0xB6
        //TODO: 0xB7
        //TODO: 0xB8
        //TODO: 0xB9
        //TODO: 0xBA
        //TODO: 0xBB
        //TODO: 0xBC
        //TODO: 0xBD
        //TODO: 0xBE
        //TODO: 0xBF
        //TODO: 0xC0
        //TODO: 0xC1
        //TODO: 0xC2
        //TODO: 0xC3
        //TODO: 0xC4
        //TODO: 0xC5
        //TODO: 0xC6
        //TODO: 0xC7
        //TODO: 0xC8
        //TODO: 0xC9
        //TODO: 0xCA
        //TODO: 0xCB
        //TODO: 0xCC
        //TODO: 0xCD
        //TODO: 0xCE
        //TODO: 0xCF
        //TODO: 0xD0
        //TODO: 0xD1
        //TODO: 0xD2
        //TODO: 0xD3
        //TODO: 0xD4
        //TODO: 0xD5
        //TODO: 0xD6
        //TODO: 0xD7
        //TODO: 0xD8
        //TODO: 0xD9
        //TODO: 0xDA
        //TODO: 0xDB
        //TODO: 0xDC
        //TODO: 0xDD
        //TODO: 0xDE
        //TODO: 0xDF
        //TODO: 0xE0
        //TODO: 0xE1
        //TODO: 0xE2
        //TODO: 0xE3
        //TODO: 0xE4
        //TODO: 0xE5
        //TODO: 0xE6
        //TODO: 0xE7
        //TODO: 0xE8
        //TODO: 0xE9
        //TODO: 0xEA
        //TODO: 0xEB
        //TODO: 0xEC
        //TODO: 0xED
        //TODO: 0xEE
        //TODO: 0xEF
        //TODO: 0xF0
        //TODO: 0xF1
        //TODO: 0xF2
        //TODO: 0xF3
        //TODO: 0xF4
        //TODO: 0xF5
        //TODO: 0xF6
        //TODO: 0xF7
        //TODO: 0xF8
        //TODO: 0xF9
        //TODO: 0xFA
        //TODO: 0xFB
        //TODO: 0xFC
        //TODO: 0xFD
        //TODO: 0xFE
        //TODO: 0xFF
        default:
            fatalError("extended opCode 0x\(opCode.hex) not supported")
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
    
    mutating func increment(register: RegisterType16, partOfOtherOpCode: Bool = false) {
        var value = registers.read(register: register)
        
        registers.write(register: register, value: value.addingReportingOverflow(1).partialValue)
        
        if !partOfOtherOpCode {
            cycles += 8
        }
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
        
        cycles += 12
    }
    
    mutating func decrement(indirect register: RegisterType16) {
        var currentValue = memory.read(location: registers.read(register: register))
        var newValue = currentValue.subtractingReportingOverflow(1).partialValue
        memory.write(location: registers.read(register: register), value: newValue)
        
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
        let lsb = UInt16(returnAndIncrement(indirect: .PC))
        let msb = UInt16(returnAndIncrement(indirect: .PC))
        let value = msb << 8 | lsb
        
        registers.write(register: register, value: value)
        
        cycles += 12
    }
    
    mutating func loadFromMemory(to register: RegisterType8, masked: Bool) {
        let lsb = UInt16(returnAndIncrement(indirect: .PC))
        let msb = masked ? UInt16(0xFF) : UInt16(returnAndIncrement(indirect: .PC))
        let value = msb << 8 | lsb
        
        registers.write(register: register, value: memory.read(location: value))
        
        cycles += masked ? 12 : 16
    }
    
    mutating func loadToMemory(from register: RegisterType8, masked: Bool = false) {
        let lsb = returnAndIncrement(indirect: .PC)
        let msb = masked ? 0xFF : returnAndIncrement(indirect: .PC)
        
        let location = UInt16(msb) << 8 | UInt16(lsb)

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
            let address = Int8(truncatingIfNeeded: returnAndIncrement(indirect: .PC))
            let address16Bit = UInt16(bitPattern: Int16(address))

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
            registers.write(register: .PC, value: UInt16(bitPattern: Int16(truncatingIfNeeded: registers.read(register: .PC)) + address))
            cycles += 12
        } else {
            cycles += 8
        }
        
    }
    
    mutating func jumpIf(flag: FlagType) {
        let address_raw = Int8(truncatingIfNeeded: returnAndIncrement(indirect: .PC))
        let address = Int16(address_raw)
        
        
        if registers.read(flag: flag) {
            registers.write(register: .PC, value: UInt16(bitPattern: Int16(truncatingIfNeeded: registers.read(register: .PC)) + address))
            cycles += 12
        } else {
            cycles += 8
        }
        
    }
    
    mutating func jump(to register: RegisterType16) {
        registers.write(register: .PC, value: registers.read(register: register))
        
        cycles += 4
    }
    
    mutating func set(ime: Bool) {
        registers.write(ime: ime)
        cycles += 4
        state = .Running
    }
    
    mutating func call() {
        let lsb = returnAndIncrement(indirect: .PC)
        let msb = returnAndIncrement(indirect: .PC)
        let value = UInt16(msb) << 8 | UInt16(lsb)
        
        let pc = registers.read(register: .PC)
        let pcMsb = UInt8(pc >> 8)
        let pcLsb = UInt8(truncatingIfNeeded: pc)

        decrement(register: .SP)
        memory.write(location: registers.read(register: .SP), value: pcMsb)
        decrement(register: .SP)
        memory.write(location: registers.read(register: .SP), value: pcLsb)
        
        registers.write(register: .PC, value: value)

        cycles += 24
    }
    
    mutating func callIfNot(flag: FlagType) {
        let lsb = UInt16(returnAndIncrement(indirect: .PC))
        let msb = UInt16(returnAndIncrement(indirect: .PC))

        let value = msb << 8 | lsb

        if !registers.read(flag: flag) {
            let pc = registers.read(register: .PC)
            let pcMsb = UInt8(pc >> 8)
            let pcLsb = UInt8(truncatingIfNeeded: pc)

            decrement(register: .SP)
            memory.write(location: registers.read(register: .SP), value: pcMsb)
            decrement(register: .SP)
            memory.write(location: registers.read(register: .SP), value: pcLsb)
            
            registers.write(register: .PC, value: value)

            cycles += 24
            
        } else {
            cycles += 12
        }
    }
    
    mutating func ret() {
        let lsb = UInt16(returnAndIncrement(indirect: .SP))
        let msb = UInt16(returnAndIncrement(indirect: .SP))

        let value = msb << 8 | lsb

        registers.write(register: .PC, value: value)

        cycles += 16
    }
    
    mutating func retIfSet(flag: FlagType) {
        if registers.read(flag: flag) {
            let lsb = UInt16(returnAndIncrement(indirect: .SP))
            let msb = UInt16(returnAndIncrement(indirect: .SP))

            let value = msb << 8 | lsb

            registers.write(register: .PC, value: value)

            self.cycles += 20;
        } else {
            self.cycles += 8;
        }
    }
    
    mutating func retIfNotSet(flag: FlagType) {
        if !registers.read(flag: flag) {
            let lsb = UInt16(returnAndIncrement(indirect: .SP))
            let msb = UInt16(returnAndIncrement(indirect: .SP))

            let value = msb << 8 | lsb

            registers.write(register: .PC, value: value)

            self.cycles += 20;
        } else {
            self.cycles += 8;
        }
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
    
    mutating func or(register: RegisterType8) {
        let a = registers.read(register: .A)
        let value = registers.read(register: register)
        let result = a | value;

        registers.write(register: .A, value: result)

        registers.write(flag: .Zero, set: result == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: false)

        cycles += 4
    }
    
    mutating func or(indirect register: RegisterType16) {
        let a = registers.read(register: .A)
        let value = memory.read(location: registers.read(register: register))
        let result = a | value;

        registers.write(register: .A, value: result)

        registers.write(flag: .Zero, set: result == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: false)

        cycles += 8
    }
    
    mutating func xor() {
        let a = registers.read(register: .A)
        let value = returnAndIncrement(indirect: .PC)
        let result = a ^ value

        registers.write(register: .A, value: result)

        registers.write(flag: .Zero, set: result == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: false)

        cycles += 4
    }
    
    mutating func xor(register: RegisterType8) {
        let a = registers.read(register: .A)
        let value = registers.read(register: register)
        let result = a ^ value

        registers.write(register: .A, value: result)

        registers.write(flag: .Zero, set: result == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: false)

        cycles += 4
    }
    
    mutating func xor(indirect register: RegisterType16) {
        let a = registers.read(register: .A)
        let value = memory.read(location: registers.read(register: register))
        let result = a ^ value

        registers.write(register: .A, value: result)

        registers.write(flag: .Zero, set: result == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: false)

        cycles += 8
    }
    
    mutating func and() {
        let a = registers.read(register: .A)
        let value = returnAndIncrement(indirect: .PC)
        let result = a & value

        registers.write(register: .A, value: result)

        registers.write(flag: .Zero, set: result == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: true)
        registers.write(flag: .Carry, set: false)

        cycles += 8
    }
    
    mutating func add() {
        let a = registers.read(register: .A)
        let value = returnAndIncrement(indirect: .PC)
        let result = a.addingReportingOverflow(value)

        registers.write(register: .A, value: result.partialValue)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: (a & 0xF) + (value & 0xF) > 0xF)
        registers.write(flag: .Carry, set: result.overflow)

        cycles += 8
    }
    
    mutating func addWithCarry() {
        let a = registers.read(register: .A)
        let value = returnAndIncrement(indirect: .PC)
        let carry = UInt8(registers.read(flag: .Carry))
        
        var resultCarry = a.addingReportingOverflow(carry)
        var result = resultCarry.partialValue.addingReportingOverflow(value)
        

        registers.write(register: .A, value: result.partialValue)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: (a & 0xF) + (value & 0xF) + (carry & 0xF) > 0xF)
        registers.write(flag: .Carry, set: resultCarry.overflow || result.overflow)

        cycles += 8
    }
    
    mutating func add(register: RegisterType16) {
        let initialValue = registers.read(register: .HL)
        let value = registers.read(register: register)
        let (result, overflow) = initialValue.addingReportingOverflow(value)


        registers.write(register: .HL, value: result)

        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .Carry, set: overflow)
        registers.write(flag: .HalfCarry, set: (initialValue & 0x0FFF) + (value & 0x0FFF) > 0x0FFF)

        cycles += 8
    }
    
    mutating func sub() {
        let a = registers.read(register: .A)
        let value = returnAndIncrement(indirect: .PC)
        let result = a.subtractingReportingOverflow(value)

        registers.write(register: .A, value: result.partialValue)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .HalfCarry, set: Int8(a & 0xF) - Int8(value & 0xF) < 0)
        registers.write(flag: .Carry, set: result.overflow)

        cycles += 8
    }
    
    mutating func copy() {
        let regValue = registers.read(register: .A)
        let value = returnAndIncrement(indirect: .PC)
        let result = regValue.subtractingReportingOverflow(value)
        
        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .HalfCarry, set: Int8(truncatingIfNeeded: regValue & 0xF) - Int8(truncatingIfNeeded: value & 0xF) < 0)
        registers.write(flag: .Carry, set: result.overflow)

        cycles += 8
    }
    
    mutating func setBit(data: UInt8, bit: UInt8, state: Bool) -> UInt8 {
        let mask = UInt8(1 << bit)
        var newValue = data
        
        if state {
            newValue = (data | mask)
        } else {
            newValue = data & (mask ^ 0xFF)
        }
        
        return newValue
    }

    mutating func getBit(data: UInt8, bit: UInt8) -> Bool {
        let value = (data >> bit) & 1
        
        return value != 0
    }
    
    mutating func shiftRight(register: RegisterType8) {
        var value = registers.read(register: register)
        let zeroBit = getBit(data: value, bit: 0)

        value >>= 1

        value = setBit(data: value, bit: 7, state: false)

        registers.write(register: register, value: value)

        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: zeroBit)

        cycles += 8
    }
    
    mutating func shiftRight(indirect register: RegisterType16) {
        var value = memory.read(location: registers.read(register: register))
        let zeroBit = getBit(data: value, bit: 0)
        
        value >>= 1

        value = setBit(data: value, bit: 7, state: false)

        memory.write(location: registers.read(register: register), value: value)

        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: zeroBit)

        cycles += 16
    }
    
    mutating func rotateRight(register: RegisterType8, zeroDependant: Bool = true) {
        var value = registers.read(register: register)
        let zeroBit = getBit(data: value, bit: 0)
        let carry = registers.read(flag: .Carry)
        
        value >>= 1

        value = setBit(data: value, bit: 7, state: carry)

        registers.write(register: register, value: value)

        registers.write(flag: .Zero, set: zeroDependant ? value == 0 : false)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: zeroBit)

        cycles += 8
    }
    
    mutating func rotateRight(indirect register: RegisterType16) {
        var value = memory.read(location: registers.read(register: register))
        let zeroBit = getBit(data: value, bit: 0)
        let carry = registers.read(flag: .Carry)
        
        value >>= 1

        value = setBit(data: value, bit: 7, state: carry)

        memory.write(location: registers.read(register: register), value: value)

        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: zeroBit)

        cycles += 8
    }
}

enum JumpType {
   case memorySigned8Bit, memoryUnsigned16Bit
}
