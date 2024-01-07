//
//  PPU.swift
//
//
//  Created by Glenn Hevey on 4/1/2024.
//

import Foundation

struct Pixel {
    
}

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
    
    public func createTile() -> [Int] {
        let bytes: [UInt8] = [0x3C, 0x7E, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x7E, 0x5E, 0x7E, 0x0A, 0x7C, 0x56, 0x38, 0x7C]
        var pixelRows = [Int]()
        
        for row in stride(from: 0, to: bytes.count, by: 2) {
            pixelRows.append(contentsOf: createPixelRow(byte1: bytes[row], byte2: bytes[row+1]))
        }
        
       return pixelRows
    }
    
    func createPixelRow(byte1: UInt8, byte2: UInt8) -> [Int] {
        var colourIds = [Int](repeating: 0, count: 8)
        
        for bit in 0..<8 {
            let msb = getBit(data: byte2, bit: UInt8(bit))
            let lsb = getBit(data: byte1, bit: UInt8(bit))
            
            if msb {
                if lsb {
                    colourIds[7-bit] = 3
                } else {
                    colourIds[7-bit] = 2
                }
            } else {
                if lsb {
                    colourIds[7-bit] = 1
                } else {
                    colourIds[7-bit] = 0
                }
            }
        }
        
        return colourIds
    }
    
    func getBit(data: UInt8, bit: UInt8) -> Bool {
        let value = (data >> bit) & 1
        
        return value != 0
    }
}

enum PPUMode {
    case VerticalBlank
    case OAM
    case Draw
    case HorizontalBlank
}

