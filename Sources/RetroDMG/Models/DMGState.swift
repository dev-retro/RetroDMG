//
//  DMGState.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 14/9/2024.
//

import RetroKit
import SwiftUI

@Observable
public class DMGState: RetroState {
    // Registers
    public var a: RetroStateItem<UInt8>
    public var b: RetroStateItem<UInt8>
    public var c: RetroStateItem<UInt8>
    public var d: RetroStateItem<UInt8>
    public var e: RetroStateItem<UInt8>
    public var f: RetroStateItem<UInt8>
    public var h: RetroStateItem<UInt8>
    public var l: RetroStateItem<UInt8>
    public var sp: RetroStateItem<UInt16>
    public var pc: RetroStateItem<UInt16>
    public var ime: RetroStateItem<Bool>
    
    //Input
    public var JoyP: RetroStateItem<UInt8>
    public var InputA: RetroStateItem<Bool>
    public var InputB: RetroStateItem<Bool>
    public var InputSelect: RetroStateItem<Bool>
    public var InputStart: RetroStateItem<Bool>
    public var InputRight: RetroStateItem<Bool>
    public var InputLeft: RetroStateItem<Bool>
    public var InputUp: RetroStateItem<Bool>
    public var InputDown: RetroStateItem<Bool>
    public var InputButtons: RetroStateItem<Bool>
    public var InputDPad: RetroStateItem<Bool>
    
    public var PcLoc: RetroStateItem<String>
    public var PcLoc1: RetroStateItem<String>
    public var PcLoc2: RetroStateItem<String>
    public var PcLoc3: RetroStateItem<String>
    
    
    public init() {
        a = RetroStateItem<UInt8>(name: "a", displayName: "A", type: .Number, value: 0x00)
        b = RetroStateItem<UInt8>(name: "b", displayName: "B", type: .Number, value: 0x00)
        c = RetroStateItem<UInt8>(name: "c", displayName: "C", type: .Number, value: 0x00)
        d = RetroStateItem<UInt8>(name: "d", displayName: "D", type: .Number, value: 0x00)
        e = RetroStateItem<UInt8>(name: "e", displayName: "E", type: .Number, value: 0x00)
        f = RetroStateItem<UInt8>(name: "f", displayName: "F", type: .Number, value: 0x00)
        h = RetroStateItem<UInt8>(name: "h", displayName: "H", type: .Number, value: 0x00)
        l = RetroStateItem<UInt8>(name: "l", displayName: "L", type: .Number, value: 0x00)
        sp = RetroStateItem<UInt16>(name: "sp", displayName: "SP", type: .Number, value: 0x0000)
        pc = RetroStateItem<UInt16>(name: "pc", displayName: "PC", type: .Number, value: 0x0000)
        ime = RetroStateItem<Bool>(name: "ime", displayName: "IME", type: .Bool, value: false)
        
        JoyP = RetroStateItem(name: "JoyP", displayName: "JoyP", type: .Number, value: 0x00)
        InputA = RetroStateItem(name: "inputA", displayName: "A", type: .Number, value: false)
        InputB = RetroStateItem(name: "inputB", displayName: "B", type: .Bool, value: false)
        InputSelect = RetroStateItem(name: "inputSelect", displayName: "Select", type: .Bool, value: false)
        InputStart = RetroStateItem(name: "inputStart", displayName: "Start", type: .Bool, value: false)
        InputRight = RetroStateItem(name: "inputRight", displayName: "Right", type: .Number, value: false)
        InputLeft = RetroStateItem(name: "inputLeft", displayName: "Left", type: .Bool, value: false)
        InputUp = RetroStateItem(name: "inputUp", displayName: "Up", type: .Bool, value: false)
        InputDown = RetroStateItem(name: "inputDown", displayName: "Down", type: .Bool, value: false)
        InputButtons = RetroStateItem(name: "inputSelectButtons", displayName: "Select Buttons", type: .Bool, value: false)
        InputDPad = RetroStateItem(name: "inputDPadButtons", displayName: "D-Pad Buttons", type: .Bool, value: false)
        
        PcLoc = RetroStateItem(name: "location", displayName: "Location", type: .String, value: "")
        PcLoc1 = RetroStateItem(name: "location1", displayName: "Location + 1", type: .String, value: "")
        PcLoc2 = RetroStateItem(name: "location2", displayName: "Location + 2", type: .String, value: "")
        PcLoc3 = RetroStateItem(name: "location3", displayName: "Location + 3", type: .String, value: "")
    }
}
