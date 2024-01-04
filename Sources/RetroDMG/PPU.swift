//
//  PPU.swift
//
//
//  Created by Glenn Hevey on 4/1/2024.
//

import Foundation

struct PPU {
    var memory: [UInt8]
    var controlRegister: UInt8
    var statusRegister: UInt8
//    let VRAM0: [UInt8]
//    let VRAM1: [UInt8]
    
    init() {
        memory = [UInt8](repeating: 0, count: 0x2000)
        controlRegister = UInt8()
        statusRegister = UInt8()
    }
}
