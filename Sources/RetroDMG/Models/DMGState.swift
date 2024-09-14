//
//  DMGState.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 14/9/2024.
//

public struct DMGState {
    public var a: UInt8
    public var b: UInt8
    public var c: UInt8
    public var d: UInt8
    public var e: UInt8
    public var f: UInt8
    public var h: UInt8
    public var l: UInt8
    public var sp: UInt16
    public var pc: UInt16
    public var ime: Bool
    
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
}
