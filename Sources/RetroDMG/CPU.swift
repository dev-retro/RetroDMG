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
    var bus: Bus
    
    init() {
        registers = Registers()
        cycles = 0
        state = .Running
        bus = Bus()
    }
    
    mutating func start() {
        if !bus.bootromLoaded {
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
        
//        print("A: \(registers.read(register: .A).hex) F: \(registers.read(register: .F).hex) B: \(registers.read(register: .B).hex) C: \(registers.read(register: .C).hex) D: \(registers.read(register: .D).hex) E: \(registers.read(register: .E).hex) H: \(registers.read(register: .H).hex) L: \(registers.read(register: .L).hex) SP: \(registers.read(register: .SP).hex) PC: 00:\(registers.read(register: .PC).hex) (\(bus.read(location: registers.read(register: .PC)).hex) \(bus.read(location: registers.read(register: .PC)+1).hex) \(bus.read(location: registers.read(register: .PC)+2).hex) \(bus.read(location: registers.read(register: .PC)+3).hex))")
        
        
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
        case 0x07:
            rotateLeftCarry(register: .A, zeroDependant: false)
        case 0x08:
            loadToMemory(from: .SP)
        case 0x09:
            add(register: .BC)
        case 0x0A:
            load(register: .A, indirect: .BC)
        case 0x0B:
            decrement(register: .BC)
        case 0x0C:
            increment(register: .C)
        case 0x0D:
            decrement(register: .C)
        case 0x0E:
            load(from: .PC, to: .C)
        case 0x0F:
            rotateRightCarry(register: .A, zeroDependant: false)
        //TODO: 0x10
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
        case 0x17:
            rotateLeft(register: .A, zeroDependant: false)
        case 0x18:
            jump(type: .memorySigned8Bit)
        case 0x19:
            add(register: .DE)
        case 0x1A:
            load(register: .A, indirect: .DE)
        case 0x1B:
            decrement(register: .DE)
        case 0x1C:
            increment(register: .E)
        case 0x1D:
            decrement(register: .E)
        case 0x1E:
            load(from: .PC, to: .E)
        case 0x1F:
            rotateRight(register: .A, zeroDependant: false)
        case 0x20:
            jumpIfNot(type: .memorySigned8Bit, flag: .Zero)
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
        case 0x27:
            daa()
        case 0x28:
            jumpIf(type: .memorySigned8Bit, flag: .Zero)
        case 0x29:
            add(register: .HL)
        case 0x2A:
            load(register: .A, indirect: .HL)
            increment(register: .HL, partOfOtherOpCode: true)
        case 0x2B:
            decrement(register: .HL)
        case 0x2C:
            increment(register: .L)
        case 0x2D:
            decrement(register: .L)
        case 0x2E:
            load(from: .PC, to: .L)
        case 0x2F:
            cpl()
        case 0x30:
            jumpIfNot(type: .memorySigned8Bit, flag: .Carry)
        case 0x31:
            loadFromMemory(to: .SP)
        case 0x32:
            load(indirect: .HL, register: .A)
            decrement(register: .HL, partOfOtherOpCode: true)
        case 0x33:
            increment(register: .SP)
        case 0x34:
            increment(indirect: .HL)
        case 0x35:
            decrement(indirect: .HL)
        case 0x36:
            load(indirect: .HL)
        case 0x37:
            setCarryFlag()
        case 0x38:
            jumpIf(type: .memorySigned8Bit, flag: .Carry)
        case 0x39:
            add(register: .SP)
        case 0x3A:
            load(register: .A, indirect: .HL)
            decrement(register: .HL, partOfOtherOpCode: true)
        case 0x3B:
            decrement(register: .SP)
        case 0x3C:
            increment(register: .A)
        case 0x3D:
            decrement(register: .A)
        case 0x3E:
            load(from: .PC, to: .A)
        case 0x3F:
            ccf()
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
        case 0x80:
            add(register: .B)
        case 0x81:
            add(register: .C)
        case 0x82:
            add(register: .D)
        case 0x83:
            add(register: .E)
        case 0x84:
            add(register: .H)
        case 0x85:
            add(register: .L)
        case 0x86:
            add(indirect: .HL)
        case 0x87:
            add(register: .A)
        case 0x88:
            adc(register: .B)
        case 0x89:
            adc(register: .C)
        case 0x8A:
            adc(register: .D)
        case 0x8B:
            adc(register: .E)
        case 0x8C:
            adc(register: .H)
        case 0x8D:
            adc(register: .L)
        case 0x8E:
            adc(indirect: .HL)
        case 0x8F:
            adc(register: .A)
        case 0x90:
            sub(register: .B)
        case 0x91:
            sub(register: .C)
        case 0x92:
            sub(register: .D)
        case 0x93:
            sub(register: .E)
        case 0x94:
            sub(register: .H)
        case 0x95:
            sub(register: .L)
        case 0x96:
            sub(indirect: .HL)
        case 0x97:
            sub(register: .A)
        case 0x98:
            sbc(register: .B)
        case 0x99:
            sbc(register: .C)
        case 0x9A:
            sbc(register: .D)
        case 0x9B:
            sbc(register: .E)
        case 0x9C:
            sbc(register: .H)
        case 0x9D:
            sbc(register: .L)
        case 0x9E:
            sbc(indirect: .HL)
        case 0x9F:
            sbc(register: .A)
        case 0xA0:
            and(register: .B)
        case 0xA1:
            and(register: .C)
        case 0xA2:
            and(register: .D)
        case 0xA3:
            and(register: .E)
        case 0xA4:
            and(register: .H)
        case 0xA5:
            and(register: .L)
        case 0xA6:
            and(indirect: .HL)
        case 0xA7:
            and(register: .A)
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
        case 0xB8:
            cp(register: .B)
        case 0xB9:
            cp(register: .C)
        case 0xBA:
            cp(register: .D)
        case 0xBB:
            cp(register: .E)
        case 0xBC:
            cp(register: .H)
        case 0xBD:
            cp(register: .L)
        case 0xBE:
            cp(indirect: .HL)
        case 0xBF:
            cp(register: .A)
        case 0xC0:
            retIfNotSet(flag: .Zero)
        case 0xC1:
            pop(register: .BC)
        case 0xC2:
            jumpIfNot(type: .memoryUnsigned16Bit, flag: .Zero)
        case 0xC3:
            jump(type: .memoryUnsigned16Bit)
        case 0xC4:
            callIfNot(flag: .Zero)
        case 0xC5:
            push(register: .BC)
        case 0xC6:
            add()
        case 0xC7:
            rst(value: 0x00)
        case 0xC8:
            retIfSet(flag: .Zero)
        case 0xC9:
            ret()
        case 0xCA:
            jumpIf(type: .memoryUnsigned16Bit, flag: .Zero)
        case 0xCB:
            extendedOpCodes()
        case 0xCC:
            callIf(flag: .Zero)
        case 0xCD:
            call()
        case 0xCE:
            adc()
        case 0xCF:
            rst(value: 0x08)
        case 0xD0:
            retIfNotSet(flag: .Carry)
        case 0xD1:
            pop(register: .DE)
        case 0xD2:
            jumpIfNot(type: .memoryUnsigned16Bit, flag: .Carry)
        case 0xD3:
            return //Not Used
        case 0xD4:
            callIfNot(flag: .Carry)
        case 0xD5:
            push(register: .DE)
        case 0xD6:
            sub()
        case 0xD7:
            rst(value: 0x10)
        case 0xD8:
            retIfSet(flag: .Carry)
        case 0xD9:
            reti()
        case 0xDA:
            jumpIf(type: .memoryUnsigned16Bit, flag: .Carry)
        case 0xDB:
            return //Not Used
        case 0xDC:
            callIf(flag: .Carry)
        case 0xDE:
            sbc()
        case 0xDF:
            rst(value: 0x18)
        case 0xE0:
            loadToMemory(from: .A, masked: true)
        case 0xE1:
            pop(register: .HL)
        case 0xE2:
            loadToMemory(masked: .C)
        case 0xE3:
            return //Not Used
        case 0xE4:
            return //Not Used
        case 0xE5:
            push(register: .HL)
        case 0xE6:
            and()
        case 0xE7:
            rst(value: 0x20)
        case 0xE8:
            addSigned(to: .SP, cycles: 16)
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
        case 0xEF:
            rst(value: 0x28)
        case 0xF0:
            loadFromMemory(to: .A, masked: true)
        case 0xF1:
            pop(register: .AF)
        case 0xF2:
            loadFromMemory(to: .A, from: .C)
        case 0xF3:
            set(ime: false)
        case 0xF4:
            return //Not Used
        case 0xF5:
            push(register: .AF)
        case 0xF6:
            or()
        case 0xF7:
            rst(value: 0x30)
        case 0xF8:
            addSigned(to: .HL, cycles: 12)
        case 0xF9:
            load(from: .HL, to: .SP)
        case 0xFA:
            loadFromMemory(to: .A, masked: false)
        case 0xFB:
            setIME()
        case 0xFC:
            return //Not Used
        case 0xFD:
            return //Not Used
        case 0xFE:
            copy()
        case 0xFF:
            rst(value: 0x38)
        default:
            fatalError("opCode 0x\(opCode.hex) not supported")
        }
    }
    
    mutating func extendedOpCodes() {
        let opCode = returnAndIncrement(indirect: .PC)
        
        switch opCode {
        case 0x00:
            rotateLeftCarry(register: .B)
        case 0x01:
            rotateLeftCarry(register: .C)
        case 0x02:
            rotateLeftCarry(register: .D)
        case 0x03:
            rotateLeftCarry(register: .E)
        case 0x04:
            rotateLeftCarry(register: .H)
        case 0x05:
            rotateLeftCarry(register: .L)
        case 0x06:
            rotateLeftCarry(indirect: .HL)
        case 0x07:
            rotateLeftCarry(register: .A)
        case 0x08:
            rotateRightCarry(register: .B)
        case 0x09:
            rotateRightCarry(register: .C)
        case 0x0A:
            rotateRightCarry(register: .D)
        case 0x0B:
            rotateRightCarry(register: .E)
        case 0x0C:
            rotateRightCarry(register: .H)
        case 0x0D:
            rotateRightCarry(register: .L)
        case 0x0E:
            rotateRightCarry(indirect: .HL)
        case 0x0F:
            rotateRightCarry(register: .A)
        case 0x10:
            rotateLeft(register: .B)
        case 0x11:
            rotateLeft(register: .C)
        case 0x12:
            rotateLeft(register: .D)
        case 0x13:
            rotateLeft(register: .E)
        case 0x14:
            rotateLeft(register: .H)
        case 0x15:
            rotateLeft(register: .L)
        case 0x16:
            rotateLeft(indirect: .HL)
        case 0x17:
            rotateLeft(register: .A)
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
        case 0x20:
            shiftLeftArithmatically(register: .B)
        case 0x21:
            shiftLeftArithmatically(register: .C)
        case 0x22:
            shiftLeftArithmatically(register: .D)
        case 0x23:
            shiftLeftArithmatically(register: .E)
        case 0x24:
            shiftLeftArithmatically(register: .H)
        case 0x25:
            shiftLeftArithmatically(register: .L)
        case 0x26:
            shiftLeftArithmatically(indirect: .HL)
        case 0x27:
            shiftLeftArithmatically(register: .A)
        case 0x28:
            shiftRightArithmatically(register: .B)
        case 0x29:
            shiftRightArithmatically(register: .C)
        case 0x2A:
            shiftRightArithmatically(register: .D)
        case 0x2B:
            shiftRightArithmatically(register: .E)
        case 0x2C:
            shiftRightArithmatically(register: .H)
        case 0x2D:
            shiftRightArithmatically(register: .L)
        case 0x2E:
            shiftRightArithmatically(indirect: .HL)
        case 0x2F:
            shiftRightArithmatically(register: .A)
        case 0x30:
            swap(register: .B)
        case 0x31:
            swap(register: .C)
        case 0x32:
            swap(register: .D)
        case 0x33:
            swap(register: .E)
        case 0x34:
            swap(register: .H)
        case 0x35:
            swap(register: .L)
        case 0x36:
            swap(indirect: .HL)
        case 0x37:
            swap(register: .A)
        case 0x38:
            shiftRightLogically(register: .B)
        case 0x39:
            shiftRightLogically(register: .C)
        case 0x3A:
            shiftRightLogically(register: .D)
        case 0x3B:
            shiftRightLogically(register: .E)
        case 0x3C:
            shiftRightLogically(register: .H)
        case 0x3D:
            shiftRightLogically(register: .L)
        case 0x3E:
            shiftRightLogically(indirect: .HL)
        case 0x3F:
            shiftRightLogically(register: .A)
        case 0x40:
            bit(register: .B, bit: 0)
        case 0x41:
            bit(register: .C, bit: 0)
        case 0x42:
            bit(register: .D, bit: 0)
        case 0x43:
            bit(register: .E, bit: 0)
        case 0x44:
            bit(register: .H, bit: 0)
        case 0x45:
            bit(register: .L, bit: 0)
        case 0x46:
            bit(indirect: .HL, bit: 0)
        case 0x47:
            bit(register: .A, bit: 0)
        case 0x48:
            bit(register: .B, bit: 1)
        case 0x49:
            bit(register: .C, bit: 1)
        case 0x4A:
            bit(register: .D, bit: 1)
        case 0x4B:
            bit(register: .E, bit: 1)
        case 0x4C:
            bit(register: .H, bit: 1)
        case 0x4D:
            bit(register: .L, bit: 1)
        case 0x4E:
            bit(indirect: .HL, bit: 1)
        case 0x4F:
            bit(register: .A, bit: 1)
        case 0x50:
            bit(register: .B, bit: 2)
        case 0x51:
            bit(register: .C, bit: 2)
        case 0x52:
            bit(register: .D, bit: 2)
        case 0x53:
            bit(register: .E, bit: 2)
        case 0x54:
            bit(register: .H, bit: 2)
        case 0x55:
            bit(register: .L, bit: 2)
        case 0x56:
            bit(indirect: .HL, bit: 2)
        case 0x57:
            bit(register: .A, bit: 2)
        case 0x58:
            bit(register: .B, bit: 3)
        case 0x59:
            bit(register: .C, bit: 3)
        case 0x5A:
            bit(register: .D, bit: 3)
        case 0x5B:
            bit(register: .E, bit: 3)
        case 0x5C:
            bit(register: .H, bit: 3)
        case 0x5D:
            bit(register: .L, bit: 3)
        case 0x5E:
            bit(indirect: .HL, bit: 3)
        case 0x5F:
            bit(register: .A, bit: 3)
        case 0x60:
            bit(register: .B, bit: 4)
        case 0x61:
            bit(register: .C, bit: 4)
        case 0x62:
            bit(register: .D, bit: 4)
        case 0x63:
            bit(register: .E, bit: 4)
        case 0x64:
            bit(register: .H, bit: 4)
        case 0x65:
            bit(register: .L, bit: 4)
        case 0x66:
            bit(indirect: .HL, bit: 4)
        case 0x67:
            bit(register: .A, bit: 4)
        case 0x68:
            bit(register: .B, bit: 5)
        case 0x69:
            bit(register: .C, bit: 5)
        case 0x6A:
            bit(register: .D, bit: 5)
        case 0x6B:
            bit(register: .E, bit: 5)
        case 0x6C:
            bit(register: .H, bit: 5)
        case 0x6D:
            bit(register: .L, bit: 5)
        case 0x6E:
            bit(indirect: .HL, bit: 5)
        case 0x6F:
            bit(register: .A, bit: 5)
        case 0x70:
            bit(register: .B, bit: 6)
        case 0x71:
            bit(register: .C, bit: 6)
        case 0x72:
            bit(register: .D, bit: 6)
        case 0x73:
            bit(register: .E, bit: 6)
        case 0x74:
            bit(register: .H, bit: 6)
        case 0x75:
            bit(register: .L, bit: 6)
        case 0x76:
            bit(indirect: .HL, bit: 6)
        case 0x77:
            bit(register: .A, bit: 6)
        case 0x78:
            bit(register: .B, bit: 7)
        case 0x79:
            bit(register: .C, bit: 7)
        case 0x7A:
            bit(register: .D, bit: 7)
        case 0x7B:
            bit(register: .E, bit: 7)
        case 0x7C:
            bit(register: .H, bit: 7)
        case 0x7D:
            bit(register: .L, bit: 7)
        case 0x7E:
            bit(indirect: .HL, bit: 7)
        case 0x7F:
            bit(register: .A, bit: 7)
        case 0x80:
            set(bit: 0, register: .B, value: false)
        case 0x81:
            set(bit: 0, register: .C, value: false)
        case 0x82:
            set(bit: 0, register: .D, value: false)
        case 0x83:
            set(bit: 0, register: .E, value: false)
        case 0x84:
            set(bit: 0, register: .H, value: false)
        case 0x85:
            set(bit: 0, register: .L, value: false)
        case 0x86:
            set(bit: 0, indirect: .HL, value: false)
        case 0x87:
            set(bit: 0, register: .A, value: false)
        case 0x88:
            set(bit: 1, register: .B, value: false)
        case 0x89:
            set(bit: 1, register: .C, value: false)
        case 0x8A:
            set(bit: 1, register: .D, value: false)
        case 0x8B:
            set(bit: 1, register: .E, value: false)
        case 0x8C:
            set(bit: 1, register: .H, value: false)
        case 0x8D:
            set(bit: 1, register: .L, value: false)
        case 0x8E:
            set(bit: 1, indirect: .HL, value: false)
        case 0x8F:
            set(bit: 1, register: .A, value: false)
        case 0x90:
            set(bit: 2, register: .B, value: false)
        case 0x91:
            set(bit: 2, register: .C, value: false)
        case 0x92:
            set(bit: 2, register: .D, value: false)
        case 0x93:
            set(bit: 2, register: .E, value: false)
        case 0x94:
            set(bit: 2, register: .H, value: false)
        case 0x95:
            set(bit: 2, register: .L, value: false)
        case 0x96:
            set(bit: 2, indirect: .HL, value: false)
        case 0x97:
            set(bit: 2, register: .A, value: false)
        case 0x98:
            set(bit: 3, register: .B, value: false)
        case 0x99:
            set(bit: 3, register: .C, value: false)
        case 0x9A:
            set(bit: 3, register: .D, value: false)
        case 0x9B:
            set(bit: 3, register: .E, value: false)
        case 0x9C:
            set(bit: 3, register: .H, value: false)
        case 0x9D:
            set(bit: 3, register: .L, value: false)
        case 0x9E:
            set(bit: 3, indirect: .HL, value: false)
        case 0x9F:
            set(bit: 3, register: .A, value: false)
        case 0xA0:
            set(bit: 4, register: .B, value: false)
        case 0xA1:
            set(bit: 4, register: .C, value: false)
        case 0xA2:
            set(bit: 4, register: .D, value: false)
        case 0xA3:
            set(bit: 4, register: .E, value: false)
        case 0xA4:
            set(bit: 4, register: .H, value: false)
        case 0xA5:
            set(bit: 4, register: .L, value: false)
        case 0xA6:
            set(bit: 4, indirect: .HL, value: false)
        case 0xA7:
            set(bit: 4, register: .A, value: false)
        case 0xA8:
            set(bit: 5, register: .B, value: false)
        case 0xA9:
            set(bit: 5, register: .C, value: false)
        case 0xAA:
            set(bit: 5, register: .D, value: false)
        case 0xAB:
            set(bit: 5, register: .E, value: false)
        case 0xAC:
            set(bit: 5, register: .H, value: false)
        case 0xAD:
            set(bit: 5, register: .L, value: false)
        case 0xAE:
            set(bit: 5, indirect: .HL, value: false)
        case 0xAF:
            set(bit: 5, register: .A, value: false)
        case 0xB0:
            set(bit: 6, register: .B, value: false)
        case 0xB1:
            set(bit: 6, register: .C, value: false)
        case 0xB2:
            set(bit: 6, register: .D, value: false)
        case 0xB3:
            set(bit: 6, register: .E, value: false)
        case 0xB4:
            set(bit: 6, register: .H, value: false)
        case 0xB5:
            set(bit: 6, register: .L, value: false)
        case 0xB6:
            set(bit: 6, indirect: .HL, value: false)
        case 0xB7:
            set(bit: 6, register: .A, value: false)
        case 0xB8:
            set(bit: 7, register: .B, value: false)
        case 0xB9:
            set(bit: 7, register: .C, value: false)
        case 0xBA:
            set(bit: 7, register: .D, value: false)
        case 0xBB:
            set(bit: 7, register: .E, value: false)
        case 0xBC:
            set(bit: 7, register: .H, value: false)
        case 0xBD:
            set(bit: 7, register: .L, value: false)
        case 0xBE:
            set(bit: 7, indirect: .HL, value: false)
        case 0xBF:
            set(bit: 7, register: .A, value: false)
        case 0xC0:
            set(bit: 0, register: .B, value: true)
        case 0xC1:
            set(bit: 0, register: .C, value: true)
        case 0xC2:
            set(bit: 0, register: .D, value: true)
        case 0xC3:
            set(bit: 0, register: .E, value: true)
        case 0xC4:
            set(bit: 0, register: .H, value: true)
        case 0xC5:
            set(bit: 0, register: .L, value: true)
        case 0xC6:
            set(bit: 0, indirect: .HL, value: true)
        case 0xC7:
            set(bit: 0, register: .A, value: true)
        case 0xC8:
            set(bit: 1, register: .B, value: true)
        case 0xC9:
            set(bit: 1, register: .C, value: true)
        case 0xCA:
            set(bit: 1, register: .D, value: true)
        case 0xCB:
            set(bit: 1, register: .E, value: true)
        case 0xCC:
            set(bit: 1, register: .H, value: true)
        case 0xCD:
            set(bit: 1, register: .L, value: true)
        case 0xCE:
            set(bit: 1, indirect: .HL, value: true)
        case 0xCF:
            set(bit: 1, register: .A, value: true)
        case 0xD0:
            set(bit: 2, register: .B, value: true)
        case 0xD1:
            set(bit: 2, register: .C, value: true)
        case 0xD2:
            set(bit: 2, register: .D, value: true)
        case 0xD3:
            set(bit: 2, register: .E, value: true)
        case 0xD4:
            set(bit: 2, register: .H, value: true)
        case 0xD5:
            set(bit: 2, register: .L, value: true)
        case 0xD6:
            set(bit: 2, indirect: .HL, value: true)
        case 0xD7:
            set(bit: 2, register: .A, value: true)
        case 0xD8:
            set(bit: 3, register: .B, value: true)
        case 0xD9:
            set(bit: 3, register: .C, value: true)
        case 0xDA:
            set(bit: 3, register: .D, value: true)
        case 0xDB:
            set(bit: 3, register: .E, value: true)
        case 0xDC:
            set(bit: 3, register: .H, value: true)
        case 0xDD:
            set(bit: 3, register: .L, value: true)
        case 0xDE:
            set(bit: 3, indirect: .HL, value: true)
        case 0xDF:
            set(bit: 3, register: .A, value: true)
        case 0xE0:
            set(bit: 4, register: .B, value: true)
        case 0xE1:
            set(bit: 4, register: .C, value: true)
        case 0xE2:
            set(bit: 4, register: .D, value: true)
        case 0xE3:
            set(bit: 4, register: .E, value: true)
        case 0xE4:
            set(bit: 4, register: .H, value: true)
        case 0xE5:
            set(bit: 4, register: .L, value: true)
        case 0xE6:
            set(bit: 4, indirect: .HL, value: true)
        case 0xE7:
            set(bit: 4, register: .A, value: true)
        case 0xE8:
            set(bit: 5, register: .B, value: true)
        case 0xE9:
            set(bit: 5, register: .C, value: true)
        case 0xEA:
            set(bit: 5, register: .D, value: true)
        case 0xEB:
            set(bit: 5, register: .E, value: true)
        case 0xEC:
            set(bit: 5, register: .H, value: true)
        case 0xED:
            set(bit: 5, register: .L, value: true)
        case 0xEE:
            set(bit: 5, indirect: .HL, value: true)
        case 0xEF:
            set(bit: 5, register: .A, value: true)
        case 0xF0:
            set(bit: 6, register: .B, value: true)
        case 0xF1:
            set(bit: 6, register: .C, value: true)
        case 0xF2:
            set(bit: 6, register: .D, value: true)
        case 0xF3:
            set(bit: 6, register: .E, value: true)
        case 0xF4:
            set(bit: 6, register: .H, value: true)
        case 0xF5:
            set(bit: 6, register: .L, value: true)
        case 0xF6:
            set(bit: 6, indirect: .HL, value: true)
        case 0xF7:
            set(bit: 6, register: .A, value: true)
        case 0xF8:
            set(bit: 7, register: .B, value: true)
        case 0xF9:
            set(bit: 7, register: .C, value: true)
        case 0xFA:
            set(bit: 7, register: .D, value: true)
        case 0xFB:
            set(bit: 7, register: .E, value: true)
        case 0xFC:
            set(bit: 7, register: .H, value: true)
        case 0xFD:
            set(bit: 7, register: .L, value: true)
        case 0xFE:
            set(bit: 7, indirect: .HL, value: true)
        case 0xFF:
            set(bit: 7, register: .A, value: true)
        default:
            fatalError("extended opCode 0x\(opCode.hex) not supported")
        }
    }
    
    mutating func returnAndIncrement(indirect register: RegisterType16) -> UInt8 {
        var regValue = registers.read(register: register)
        let value = bus.read(location: regValue)
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
        registers.write(flag: .HalfCarry, set: (((registerValue & 0xF) + (1 & 0xF)) & 0x10) == 0x10)
        
    }
    
    mutating func increment(register: RegisterType16, partOfOtherOpCode: Bool = false) {
        var value = registers.read(register: register)
        value = value.addingReportingOverflow(1).partialValue
        
        registers.write(register: register, value: value)
        
        if !partOfOtherOpCode {
            cycles += 8
        }
    }
    
    mutating func increment(indirect register: RegisterType16) {
        var registerValue = registers.read(register: register)
        var value = bus.read(location: registerValue)
        var newValue = value.addingReportingOverflow(1).partialValue
        bus.write(location: registerValue, value: newValue)
        
        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: (((value & 0xF) + (1 & 0xF)) & 0x10) == 0x10)
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
        var currentValue = bus.read(location: registers.read(register: register))
        var newValue = currentValue.subtractingReportingOverflow(1).partialValue
        bus.write(location: registers.read(register: register), value: newValue)
        
        registers.write(flag: .Zero, set: newValue == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .HalfCarry, set: Int8(currentValue & 0xF) - Int8(1 & 0xF) < 0)
    }
    
    mutating func decrement(register: RegisterType16, partOfOtherOpCode: Bool = false) {
        var regValue = registers.read(register: register)
        let value = regValue.subtractingReportingOverflow(1)
        registers.write(register: register, value: value.partialValue)
        
        if !partOfOtherOpCode {
            cycles += 8
        }
    }
    
    mutating func load(from fromRegister: RegisterType8, to toRegister: RegisterType8) {
        registers.write(register: toRegister, value: registers.read(register: fromRegister))
        cycles += 4
    }
    
    mutating func load(from fromRegister: RegisterType16, to toRegister: RegisterType16) {
        registers.write(register: toRegister, value: registers.read(register: fromRegister))
        cycles += 8
    }
    
    mutating func load(register: RegisterType8, indirect: RegisterType16) {
        registers.write(register: register, value: bus.read(location: registers.read(register: indirect)))
        cycles += 8
    }
    
    mutating func load(indirect: RegisterType16, register: RegisterType8) {
        bus.write(location: registers.read(register: indirect), value: registers.read(register: register))
        cycles += 8
    }
    
    mutating func load(from fromRegister: RegisterType16, to toRegister: RegisterType8) {
        let value = returnAndIncrement(indirect: fromRegister)
        registers.write(register: toRegister, value: value)
        cycles += 8
    }
    
    mutating func load(indirect register: RegisterType16) {
        let value = returnAndIncrement(indirect: .PC)
            bus.write(location: registers.read(register: register), value: value)
            cycles += 12
    }
    
    mutating func loadFromMemory(to register: RegisterType16) {
        let lsb = UInt16(returnAndIncrement(indirect: .PC))
        let msb = UInt16(returnAndIncrement(indirect: .PC))
        let value = msb << 8 | lsb
        
        registers.write(register: register, value: value)
        
        cycles += 12
    }
    
    mutating func loadFromMemory(to toRegister: RegisterType8, from fromRegister: RegisterType8) {
        let lsb = UInt16(registers.read(register: fromRegister))
        let msb = UInt16(0xFF)
        let value = msb << 8 | lsb
        
        registers.write(register: toRegister, value: bus.read(location: value))
        
        cycles += 8
    }
    
    mutating func loadFromMemory(to register: RegisterType8, masked: Bool) {
        let lsb = UInt16(returnAndIncrement(indirect: .PC))
        let msb = masked ? UInt16(0xFF) : UInt16(returnAndIncrement(indirect: .PC))
        let value = msb << 8 | lsb
        
        registers.write(register: register, value: bus.read(location: value))
        
        cycles += masked ? 12 : 16
    }
    
    mutating func loadToMemory(from register: RegisterType8, masked: Bool = false) {
        let lsb = returnAndIncrement(indirect: .PC)
        let msb = masked ? 0xFF : returnAndIncrement(indirect: .PC)
        
        let location = UInt16(msb) << 8 | UInt16(lsb)

        bus.write(location: location, value: registers.read(register: register))
        
        cycles += masked ? 12 : 16;
    }
    
    mutating func loadToMemory(masked register: RegisterType8) {
        let lsb = registers.read(register: register)
        let msb = 0xFF
        
        let location = UInt16(msb) << 8 | UInt16(lsb)
        
        bus.write(location: location, value: registers.read(register: .A))
        
        cycles += 8
    }
    
    mutating func loadToMemory(from register: RegisterType16) {
        let lsb = returnAndIncrement(indirect: .PC)
        let msb = returnAndIncrement(indirect: .PC)
        let value = registers.read(register: register)
        
        var location = UInt16(msb) << 8 | UInt16(lsb)
        
        bus.write(location: location, value: UInt8(value >> 8))
        location += 1
        bus.write(location: location, value: UInt8(truncatingIfNeeded: value))
        
        cycles += 20
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
//        bus.write(location: location, value: UInt8)
//        
//        cycles += cycleCount
//    }
    
    mutating func jump(type: JumpType) {
        switch type {
        case .memorySigned8Bit:
            let address = Int8(bitPattern: returnAndIncrement(indirect: .PC))
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
    
    mutating func jumpIfNot(type: JumpType, flag: FlagType) {
        switch type {
        case .memorySigned8Bit:
            let address_raw = Int8(bitPattern: returnAndIncrement(indirect: .PC))
            let address = UInt16(bitPattern: Int16(address_raw))
            
            if !registers.read(flag: flag) {
                registers.write(register: .PC, value: registers.read(register: .PC).addingReportingOverflow(address).partialValue)
                cycles += 12
            } else {
                cycles += 8
            }
        case .memoryUnsigned16Bit:
            let lsb = returnAndIncrement(indirect: .PC)
            let msb = returnAndIncrement(indirect: .PC)
            if !registers.read(flag: flag) {
                let value = UInt16(msb) << 8 | UInt16(lsb);
                
                registers.write(register: .PC, value: value)
                
                cycles += 16
            } else {
                cycles += 12
            }

        }
    }
    
    mutating func jumpIf(type: JumpType, flag: FlagType) {
        switch type {
        case .memorySigned8Bit:
            let address_raw = Int8(bitPattern: returnAndIncrement(indirect: .PC))
            let address = UInt16(bitPattern: Int16(address_raw))
            
            
            if registers.read(flag: flag) {
                registers.write(register: .PC, value: registers.read(register: .PC).addingReportingOverflow(address).partialValue)
                cycles += 12
            } else {
                cycles += 8
            }
        case .memoryUnsigned16Bit:
            let lsb = returnAndIncrement(indirect: .PC)
            let msb = returnAndIncrement(indirect: .PC)
            if registers.read(flag: flag) {
                let value = UInt16(msb) << 8 | UInt16(lsb);
                
                registers.write(register: .PC, value: value)
                
                cycles += 16
            } else {
                cycles += 12
            }
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

        decrement(register: .SP, partOfOtherOpCode: true)
        bus.write(location: registers.read(register: .SP), value: pcMsb)
        decrement(register: .SP, partOfOtherOpCode: true)
        bus.write(location: registers.read(register: .SP), value: pcLsb)
        
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

            decrement(register: .SP, partOfOtherOpCode: true)
            bus.write(location: registers.read(register: .SP), value: pcMsb)
            decrement(register: .SP, partOfOtherOpCode: true)
            bus.write(location: registers.read(register: .SP), value: pcLsb)
            
            registers.write(register: .PC, value: value)

            cycles += 24
            
        } else {
            cycles += 12
        }
    }
    
    mutating func callIf(flag: FlagType) {
        let lsb = UInt16(returnAndIncrement(indirect: .PC))
        let msb = UInt16(returnAndIncrement(indirect: .PC))

        let value = msb << 8 | lsb

        if registers.read(flag: flag) {
            let pc = registers.read(register: .PC)
            let pcMsb = UInt8(pc >> 8)
            let pcLsb = UInt8(truncatingIfNeeded: pc)

            decrement(register: .SP, partOfOtherOpCode: true)
            bus.write(location: registers.read(register: .SP), value: pcMsb)
            decrement(register: .SP, partOfOtherOpCode: true)
            bus.write(location: registers.read(register: .SP), value: pcLsb)
            
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
    
    mutating func reti() {
        let lsb = UInt16(returnAndIncrement(indirect: .SP))
        let msb = UInt16(returnAndIncrement(indirect: .SP))

        let value = msb << 8 | lsb

        registers.write(register: .PC, value: value)
        registers.write(ime: true)

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
        decrement(register: .SP, partOfOtherOpCode: true)
        bus.write(location: registers.read(register: .SP), value: UInt8(value >> 8))
        decrement(register: .SP, partOfOtherOpCode: true)
        bus.write(location: registers.read(register: .SP), value: UInt8(truncatingIfNeeded: register == .AF ? value & 0xF0 : value ))

        cycles += 16
    }
    
    mutating func pop(register: RegisterType16) {
        var lsb = returnAndIncrement(indirect: .SP)
        let msb = returnAndIncrement(indirect: .SP)
        
        if register == .AF {
            lsb = lsb & 0xF0
        }
        
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
        let value = bus.read(location: registers.read(register: register))
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
        let value = bus.read(location: registers.read(register: register))
        let result = a ^ value

        registers.write(register: .A, value: result)

        registers.write(flag: .Zero, set: result == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: false)

        cycles += 8
    }
    
    mutating func and(register: RegisterType8) {
        let a = registers.read(register: .A)
        let value = registers.read(register: register)
        let result = a & value

        registers.write(register: .A, value: result)

        registers.write(flag: .Zero, set: result == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: true)
        registers.write(flag: .Carry, set: false)

        cycles += 4
    }
    
    mutating func and(indirect register: RegisterType16) {
        let a = registers.read(register: .A)
        let value = bus.read(location: registers.read(register: register))
        let result = a & value

        registers.write(register: .A, value: result)

        registers.write(flag: .Zero, set: result == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: true)
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
    
    mutating func or() {
        let a = registers.read(register: .A)
        let value = returnAndIncrement(indirect: .PC)
        let result = a | value

        registers.write(register: .A, value: result)

        registers.write(flag: .Zero, set: result == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: false)

        cycles += 8
    }
    
    mutating func add(register: RegisterType8) {
        let a = registers.read(register: .A)
        let value = registers.read(register: register)
        let result = a.addingReportingOverflow(value)

        registers.write(register: .A, value: result.partialValue)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: (((a & 0xF) + (value & 0xF)) & 0x10) == 0x10)
        registers.write(flag: .Carry, set: result.overflow)

        cycles += 4
    }
    
    mutating func add(indirect register: RegisterType16) {
        let a = registers.read(register: .A)
        let value = bus.read(location: registers.read(register: register))
        let result = a.addingReportingOverflow(value)

        registers.write(register: .A, value: result.partialValue)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: (((a & 0xF) + (value & 0xF)) & 0x10) == 0x10)
        registers.write(flag: .Carry, set: result.overflow)

        cycles += 8
    }
    
    mutating func add() {
        let a = registers.read(register: .A)
        let value = returnAndIncrement(indirect: .PC)
        let result = a.addingReportingOverflow(value)

        registers.write(register: .A, value: result.partialValue)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: (((a & 0xF) + (value & 0xF)) & 0x10) == 0x10)
        registers.write(flag: .Carry, set: result.overflow)

        cycles += 8
    }
    
    mutating func addSigned(to register: RegisterType16, cycles cyclesCount: Int32) {
        let sp = registers.read(register: .SP)
        let value = Int8(bitPattern: returnAndIncrement(indirect: .PC))
        let result = sp.addingReportingOverflow(UInt16(bitPattern: Int16(value)))

        registers.write(register: register, value: result.partialValue)
        
        let spMasked = Int8(bitPattern: UInt8(truncatingIfNeeded: sp)) & 0xF
        let valueMasked = value & 0xF
        

        registers.write(flag: .Zero, set: false)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: ((spMasked + valueMasked) & 0x10) == 0x10) // (sp & 0xFFF) + (UInt16(bitPattern: Int16(value)) & 0xFFF) > 0xFFF)
        registers.write(flag: .Carry, set: result.overflow)

        cycles += cyclesCount
    }
    
    mutating func adc(register: RegisterType8) {
        let a = registers.read(register: .A)
        let value = registers.read(register: register)
        let carry = UInt8(registers.read(flag: .Carry))
        
        var resultCarry = a.addingReportingOverflow(carry)
        var result = resultCarry.partialValue.addingReportingOverflow(value)
        

        registers.write(register: .A, value: result.partialValue)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: (((a & 0xF) + (value & 0xF) + (carry & 0xF)) & 0x10) == 0x10)
        registers.write(flag: .Carry, set: resultCarry.overflow || result.overflow)

        cycles += 4
    }
    
    
    mutating func adc(indirect register: RegisterType16) {
        let a = registers.read(register: .A)
        let value = bus.read(location: registers.read(register: register))
        let carry = UInt8(registers.read(flag: .Carry))
        
        var resultCarry = a.addingReportingOverflow(carry)
        var result = resultCarry.partialValue.addingReportingOverflow(value)
        

        registers.write(register: .A, value: result.partialValue)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: (((a & 0xF) + (value & 0xF) + (carry & 0xF)) & 0x10) == 0x10)
        registers.write(flag: .Carry, set: resultCarry.overflow || result.overflow)

        cycles += 8
    }
    
    
    mutating func adc() {
        let a = registers.read(register: .A)
        let value = returnAndIncrement(indirect: .PC)
        let carry = UInt8(registers.read(flag: .Carry))
        
        var resultCarry = a.addingReportingOverflow(carry)
        var result = resultCarry.partialValue.addingReportingOverflow(value)
        

        registers.write(register: .A, value: result.partialValue)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: (((a & 0xF) + (value & 0xF) + (carry & 0xF)) & 0x10) == 0x10)
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
        registers.write(flag: .HalfCarry, set: (((initialValue & 0xFFF) + (value & 0xFFF)) & 0x1000) == 0x1000)

        cycles += 8
    }
    
    mutating func sub(register: RegisterType8) {
        let a = registers.read(register: .A)
        let value = registers.read(register: register)
        let result = a.subtractingReportingOverflow(value)

        registers.write(register: .A, value: result.partialValue)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .HalfCarry, set: Int8(a & 0xF) - Int8(value & 0xF) < 0)
        registers.write(flag: .Carry, set: result.overflow)

        cycles += 4
    }
    
    mutating func sub(indirect register: RegisterType16) {
        let a = registers.read(register: .A)
        let value = bus.read(location: registers.read(register: .HL))
        let result = a.subtractingReportingOverflow(value)

        registers.write(register: .A, value: result.partialValue)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .HalfCarry, set: Int8(a & 0xF) - Int8(value & 0xF) < 0)
        registers.write(flag: .Carry, set: result.overflow)

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
    
    mutating func sbc(register: RegisterType8) {
        let a = registers.read(register: .A)
        let register = registers.read(register: register)
        let carry: UInt8 = registers.read(flag: .Carry) ? 1 : 0
        
        var (resultOne, overFlowOne) = a.subtractingReportingOverflow(carry)
        var (resultTwo, overFlowTwo) = resultOne.subtractingReportingOverflow(register)
        var halfCarry = Int8(Int8(bitPattern: a) & 0xF - Int8(bitPattern: register) & 0xF)
        halfCarry -= Int8(bitPattern: carry) & 0xF
            
        registers.write(register: .A, value: resultTwo)

        registers.write(flag: .Zero, set: resultTwo == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .Carry, set: overFlowOne || overFlowTwo)
        registers.write(flag: .HalfCarry, set: halfCarry < 0)

        cycles += 4
    }
    
    mutating func sbc(indirect register: RegisterType16) {
        let a = registers.read(register: .A)
        let register = bus.read(location: registers.read(register: register))
        let carry: UInt8 = registers.read(flag: .Carry) ? 1 : 0
        
        var (resultOne, overFlowOne) = a.subtractingReportingOverflow(carry)
        var (resultTwo, overFlowTwo) = resultOne.subtractingReportingOverflow(register)
        var halfCarry = Int8(Int8(bitPattern: a) & 0xF - Int8(bitPattern: register) & 0xF)
        halfCarry -= Int8(bitPattern: carry) & 0xF
            
        registers.write(register: .A, value: resultTwo)

        registers.write(flag: .Zero, set: resultTwo == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .Carry, set: overFlowOne || overFlowTwo)
        registers.write(flag: .HalfCarry, set: halfCarry < 0)

        cycles += 8
    }
    
    mutating func sbc() {
        let a = registers.read(register: .A)
        let register = returnAndIncrement(indirect: .PC)
        let carry: UInt8 = registers.read(flag: .Carry) ? 1 : 0
        
        var (resultOne, overFlowOne) = a.subtractingReportingOverflow(carry)
        var (resultTwo, overFlowTwo) = resultOne.subtractingReportingOverflow(register)
        var halfCarry = Int8(Int8(bitPattern: a) & 0xF - Int8(bitPattern: register) & 0xF)
        halfCarry -= Int8(bitPattern: carry) & 0xF
            
        registers.write(register: .A, value: resultTwo)

        registers.write(flag: .Zero, set: resultTwo == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .Carry, set: overFlowOne || overFlowTwo)
        registers.write(flag: .HalfCarry, set: halfCarry < 0)

        cycles += 8
    }
    
    mutating func copy() {
        let regValue = registers.read(register: .A)
        let value = returnAndIncrement(indirect: .PC)
        let result = regValue.subtractingReportingOverflow(value)
        
        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .HalfCarry, set: Int8(bitPattern: regValue & 0xF) - Int8(bitPattern: value & 0xF) < 0)
        registers.write(flag: .Carry, set: result.overflow)

        cycles += 8
    }
    
    mutating func setCarryFlag() {
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: true)
        
        cycles += 4
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
    
    mutating func shiftLeftArithmatically(register: RegisterType8) {
        var value = registers.read(register: register)
        let sevenBit = getBit(data: value, bit: 7)

        value <<= 1

        value = setBit(data: value, bit: 0, state: false)

        registers.write(register: register, value: value)

        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: sevenBit)

        cycles += 8
    }
    
    mutating func shiftLeftArithmatically(indirect register: RegisterType16) {
        var value = bus.read(location: registers.read(register: register))
        let sevenBit = getBit(data: value, bit: 7)
        
        value <<= 1

        value = setBit(data: value, bit: 0, state: false)

        bus.write(location: registers.read(register: register), value: value)

        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: sevenBit)

        cycles += 16
    }
    
    mutating func shiftRightArithmatically(register: RegisterType8) {
        var value = registers.read(register: register)
        let zeroBit = getBit(data: value, bit: 0)
        let sevenBit = getBit(data: value, bit: 7)

        value >>= 1
        
        value = setBit(data: value, bit: 7, state: sevenBit)
        
        registers.write(register: register, value: value)

        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: zeroBit)

        cycles += 8
    }
    
    mutating func shiftRightArithmatically(indirect register: RegisterType16) {
        var value = bus.read(location: registers.read(register: register))
        let zeroBit = getBit(data: value, bit: 0)
        let sevenBit = getBit(data: value, bit: 7)
        
        value >>= 1
        
        value = setBit(data: value, bit: 7, state: sevenBit)

        bus.write(location: registers.read(register: register), value: value)

        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: zeroBit)

        cycles += 16
    }
    
    mutating func shiftRightLogically(register: RegisterType8) {
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
    
    mutating func shiftRightLogically(indirect register: RegisterType16) {
        var value = bus.read(location: registers.read(register: register))
        let zeroBit = getBit(data: value, bit: 0)
        
        value >>= 1

        value = setBit(data: value, bit: 7, state: false)

        bus.write(location: registers.read(register: register), value: value)

        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: zeroBit)

        cycles += 16
    }
    
    mutating func rotateLeftCarry(register: RegisterType8, zeroDependant: Bool = true) {
        var value = registers.read(register: register)
        let sevenBit = getBit(data: value, bit: 7)
        
        value <<= 1

        value = setBit(data: value, bit: 0, state: sevenBit)

        registers.write(register: register, value: value)

        registers.write(flag: .Zero, set: zeroDependant ? value == 0 : false)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: sevenBit)

        cycles += zeroDependant ? 8 : 4
    }
    
    mutating func rotateLeftCarry(indirect register: RegisterType16) {
        var value = bus.read(location: registers.read(register: register))
        let sevenBit = getBit(data: value, bit: 7)
        
        value <<= 1

        value = setBit(data: value, bit: 0, state: sevenBit)

        bus.write(location: registers.read(register: register), value: value)

        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: sevenBit)

        cycles += 16
    }
    
    
    mutating func rotateLeft(register: RegisterType8, zeroDependant: Bool = true) {
        var value = registers.read(register: register)
        let sevenBit = getBit(data: value, bit: 7)
        let carry = registers.read(flag: .Carry)
        
        value <<= 1

        value = setBit(data: value, bit: 0, state: carry)

        registers.write(register: register, value: value)

        registers.write(flag: .Zero, set: zeroDependant ? value == 0 : false)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: sevenBit)

        cycles += 8
    }
    
    mutating func rotateLeft(indirect register: RegisterType16) {
        var value = bus.read(location: registers.read(register: register))
        let sevenBit = getBit(data: value, bit: 7)
        let carry = registers.read(flag: .Carry)
        
        value <<= 1

        value = setBit(data: value, bit: 0, state: carry)

        bus.write(location: registers.read(register: register), value: value)

        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: sevenBit)

        cycles += 16
    }
    
    mutating func rotateRightCarry(register: RegisterType8, zeroDependant: Bool = true) {
        var value = registers.read(register: register)
        let zeroBit = getBit(data: value, bit: 0)
        
        value >>= 1

        value = setBit(data: value, bit: 7, state: zeroBit)

        registers.write(register: register, value: value)

        registers.write(flag: .Zero, set: zeroDependant ? value == 0 : false)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: zeroBit)

        cycles += zeroDependant ? 8 : 4
    }
    
    mutating func rotateRightCarry(indirect register: RegisterType16) {
        var value = bus.read(location: registers.read(register: register))
        let zeroBit = getBit(data: value, bit: 0)
        
        value >>= 1

        value = setBit(data: value, bit: 7, state: zeroBit)

        bus.write(location: registers.read(register: register), value: value)

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
        var value = bus.read(location: registers.read(register: register))
        let zeroBit = getBit(data: value, bit: 0)
        let carry = registers.read(flag: .Carry)
        
        value >>= 1

        value = setBit(data: value, bit: 7, state: carry)

        bus.write(location: registers.read(register: register), value: value)

        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: zeroBit)

        cycles += 8
    }
    
    mutating func swap(register: RegisterType8) {
        var registerValue = registers.read(register: register)
        
        let value = (registerValue >> 4) | (registerValue << 4)
        
        registers.write(register: register, value: value)
        
        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: false)
        
        cycles += 8
    }
    
    mutating func swap(indirect: RegisterType16) {
        var value = bus.read(location: registers.read(register: .HL))
        
        value = (value >> 4) | (value << 4)
        
        bus.write(location: registers.read(register: .HL), value: value)
        
        registers.write(flag: .Zero, set: value == 0)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: false)
        
        cycles += 16
    }
    
    mutating func bit(register: RegisterType8, bit: UInt8) {
        let bit = !registers.read(register: register).get(bit: bit)
        
        registers.write(flag: .Zero, set: bit)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: true)
            
        cycles += 8
    }
    
    mutating func bit(indirect register: RegisterType16, bit: UInt8) {
        let bit = !bus.read(location: registers.read(register: register)).get(bit: bit)
        
        registers.write(flag: .Zero, set: bit)
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: true)
            
        cycles += 12
    }
    
    mutating func set(bit: UInt8, register: RegisterType8, value: Bool) {
        var regValue = registers.read(register: register)
        regValue.set(bit: bit, value: value)
        
        registers.write(register: register, value: regValue)
        cycles += 8
    }
    
    mutating func set(bit: UInt8, indirect register: RegisterType16, value: Bool) {
        var memoryValue = bus.read(location: registers.read(register: register))
        memoryValue.set(bit: bit, value: value)
        bus.write(location: registers.read(register: .HL), value: memoryValue)
        
        cycles += 16
    }
    
    mutating func setIME() {
        registers.write(ime: true)
        
        cycles += 4
    }
    
    mutating func cpl() {
        var value = ~registers.read(register: .A)
        
        registers.write(register: .A, value: value)
        
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .HalfCarry, set: true)
        
        cycles += 4
    }
    
    mutating func ccf() {
        var value = !registers.read(flag: .Carry)
        
        registers.write(flag: .Subtraction, set: false)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: value)
        
        
        cycles += 4
    }
    
    mutating func cp(register: RegisterType8) {
        let a = registers.read(register: .A)
        let value = registers.read(register: register)
        let result = a.subtractingReportingOverflow(value)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .HalfCarry, set: Int8(a & 0xF) - Int8(value & 0xF) < 0)
        registers.write(flag: .Carry, set: result.overflow)

        cycles += 4
    }
    
    mutating func cp(indirect register: RegisterType16) {
        let a = registers.read(register: .A)
        let value = bus.read(location: registers.read(register: register))
        let result = a.subtractingReportingOverflow(value)

        registers.write(flag: .Zero, set: result.partialValue == 0)
        registers.write(flag: .Subtraction, set: true)
        registers.write(flag: .HalfCarry, set: Int8(a & 0xF) - Int8(value & 0xF) < 0)
        registers.write(flag: .Carry, set: result.overflow)

        cycles += 8
    }
    
    mutating func daa() {
        let negativeFlag = registers.read(flag: .Subtraction)
        let carryFlag = registers.read(flag: .Carry)
        let halfCarryFlag = registers.read(flag: .HalfCarry)
        
        var carry = false
        
        if !negativeFlag {
            if carryFlag || registers.read(register: .A) > 0x99 {
                registers.write(register: .A, value: registers.read(register: .A).addingReportingOverflow(0x60).partialValue)
                carry = true
            }
            
            if halfCarryFlag || registers.read(register: .A) & 0x0F > 0x09 {
                registers.write(register: .A, value: registers.read(register: .A).addingReportingOverflow(0x06).partialValue)
            }
        } else if carryFlag {
        
            carry = true
            registers.write(register: .A, value: halfCarryFlag ? registers.read(register: .A).addingReportingOverflow(0x9a).partialValue : registers.read(register: .A).addingReportingOverflow(0xa0).partialValue)
        } else if halfCarryFlag {
            registers.write(register: .A, value: registers.read(register: .A).addingReportingOverflow(0xfa).partialValue)
        }


        registers.write(flag: .Zero, set: registers.read(register: .A) == 0)
        registers.write(flag: .HalfCarry, set: false)
        registers.write(flag: .Carry, set: carry)

        cycles += 4
    }
    
    mutating func rst(value: UInt8) {
        let lsb = UInt8(truncatingIfNeeded: registers.read(register: .PC) >> 8)
        let msb = UInt8(truncatingIfNeeded: registers.read(register: .PC))
        
        decrement(register: .SP)
        bus.write(location: registers.read(register: .SP), value: msb)
        decrement(register: .SP)
        bus.write(location: registers.read(register: .SP), value: lsb)
        
        registers.write(register: .PC, value: (UInt16(0x00) << 8 | UInt16(value)))
        
        cycles += 16
    }
}

enum JumpType {
   case memorySigned8Bit, memoryUnsigned16Bit
}
