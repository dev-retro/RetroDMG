//
//  Registers.swift
//
//
//  Created by Glenn Hevey on 24/12/2023.
//

import Foundation

enum RegisterType8 {
    case A, B, C, D, E, F, H, L
}

enum RegisterType16 {
    case AF, BC, DE, HL, SP, PC
}

enum FlagType {
    case Zero, Subtraction, HalfCarry, Carry
}

struct Registers {
    var a: UInt8
    var b: UInt8
    var c: UInt8
    var d: UInt8
    var e: UInt8
    var f: UInt8
    var h: UInt8
    var l: UInt8
    var sp: UInt16
    var pc: UInt16
    var ime: Bool
    
    init() {
        a = 0x00
        b = 0x00
        c = 0x00
        d = 0x00
        e = 0x00
        f = 0x00
        h = 0x00
        l = 0x00
        sp = 0x0000
        pc = 0x0000
        ime = false
    }
    
    mutating func write(register: RegisterType8, value: UInt8) {
        switch register {
        case .A:
            a = value
        case .B:
            b = value
        case .C:
            c = value
        case .D:
            d = value
        case .E:
            e = value
        case .F:
            f = value
        case .H:
            h = value
        case .L:
            l = value
        }
    }
    
    mutating func write(register: RegisterType16, value: UInt16) {
        switch register {
        case .AF:
            a = UInt8(value >> 8)
            f = UInt8(value & 0x0F)
        case .BC:
            b = UInt8(value >> 8)
            c = UInt8(value & 0x0F)
        case .DE:
            d = UInt8(value >> 8)
            e = UInt8(value & 0x0F)
        case .HL:
            h = UInt8(value >> 8)
            l = UInt8(value & 0x0F)
        case .SP:
            sp = value
        case .PC:
            pc = value
        }
    }
    
    mutating func write(flag: FlagType, set: Bool) {
        switch flag {
        case .Zero:
            let mask: UInt8 = 0b10000000
            
            if set {
                f |= mask
            } else {
                f &= mask ^ 0xFF
            }
        case .Subtraction:
            let mask: UInt8 = 0b01000000
            
            if set {
                f |= mask
            } else {
                f &= mask ^ 0xFF
            }
        case .HalfCarry:
            let mask: UInt8 = 0b00100000
            
            if set {
                f |= mask
            } else {
                f &= mask ^ 0xFF
            }
        case .Carry:
            let mask: UInt8 = 0b00010000
            
            if set {
                f |= mask
            } else {
                f &= mask ^ 0xFF
            }
        }
    }
    
    mutating func write(ime value: Bool) {
        ime = value
    }
    
    func read(register: RegisterType8) -> UInt8 {
        switch register {
        case .A:
            return a
        case .B:
            return b
        case .C:
            return c
        case .D:
            return d
        case .E:
            return e
        case .F:
            return f
        case .H:
            return h
        case .L:
            return l
        }
    }
    
    func read(register: RegisterType16) -> UInt16 {
        switch register {
        case .AF:
            return UInt16(a) << 8 | UInt16(f)
        case .BC:
            return UInt16(b) << 8 | UInt16(c)
        case .DE:
            return UInt16(d) << 8 | UInt16(e)
        case .HL:
            return UInt16(h) << 8 | UInt16(l)
        case .SP:
            return sp
        case .PC:
            return pc
        }
    }
    
    func read(flag: FlagType) -> Bool {
        switch flag {
        case .Zero:
            let mask: UInt8 = 0b10000000
            return f & mask == mask
        case .Subtraction:
            let mask: UInt8 = 0b01000000
            return f & mask == mask
        case .HalfCarry:
            let mask: UInt8 = 0b00100000
            return f & mask == mask
        case .Carry:
            let mask: UInt8 = 0b00010000
            return f & mask == mask
        }
    }
    
    func readIme() -> Bool {
        return ime
    }
}
