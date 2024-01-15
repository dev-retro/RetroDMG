//
//  PPU.swift
//
//
//  Created by Glenn Hevey on 4/1/2024.
//

import Foundation

struct PPU {
    var memory: [UInt8]
    var tilemap9800: [UInt8]
    var tilemap9C00: [UInt8]
    var viewPort: [Int]
    var scx: UInt8
    var scy: UInt8
    var ly: UInt8
    
    private var cycle: Int
    private var mode: PPUMode
    
    
    //MARK: PPU Registers
    var control: UInt8
    private var status: UInt8
    
    init() {
        memory = [UInt8](repeating: 0, count: 0x1800)
        tilemap9800 = [UInt8](repeating: 0, count: 0x0400)
        tilemap9C00 = [UInt8](repeating: 0, count: 0x0400)
        viewPort = [Int](repeating: 0, count: 22400)
        cycle = 0
        
        control = 0x00
        status = 0x80
        mode = .OAM
        
        scx = 0x00
        scy = 0x00
        
        ly = 0x00
    }
        
    //MARK: Line based rendering
    
    public mutating func fetch() {
        viewPort.removeAll()
        
        for line in 0..<144 {
            ly = UInt8(line)
            let tilemap = read(flag: .BGTileMapSelect) ? tilemap9C00 : tilemap9800
            var x = 0
            for _ in stride(from: 0, to: 160, by: 8) {
                var fetcherX = x + (Int(scx) / 8) & 0x1F
                var fetcherY = (line + Int(scy)) & 0xFF
                
                var tilemapAddress = x + ((fetcherY / 8) * 0x20)
                
                var tileNo = tilemap[Int(tilemapAddress)]
                
                var tileLocation = read(flag: .TileDataSelect) ? Int(tileNo) * 16 : 0x1000 + Int(Int8(bitPattern: tileNo)) * 16
                tileLocation += (2 * (fetcherY % 8))
                
                
                let byte1 = memory[Int(tileLocation)]
                let byte2 = memory[Int(tileLocation + 0x1)]
                var tile = createPixelRow(byte1: byte1, byte2: byte2)
                
                viewPort.append(contentsOf: tile)
                x += 1
            }
        }
    }
    
    mutating func write(mode: PPUMode) {
        self.mode = mode
    }
    
    public func readMode() -> PPUMode {
        return mode
    }
    
    public mutating func write(flag: PPURegisterType, set: Bool) {
        switch flag {
        case .LCDDisplayEnable:
            let mask: UInt8 = 0b10000000
            
            if set {
                control |= mask
            } else {
                control &= mask ^ 0xFF
            }
        case .WindowTileMapSelect:
            let mask: UInt8 = 0b01000000
            
            if set {
                control |= mask
            } else {
                control &= mask ^ 0xFF
            }
        case .WindowDisplayEnable:
            let mask: UInt8 = 0b00100000
            
            if set {
                control |= mask
            } else {
                control &= mask ^ 0xFF
            }
        case .TileDataSelect:
            let mask: UInt8 = 0b00010000
            
            if set {
                control |= mask
            } else {
                control &= mask ^ 0xFF
            }
        case .BGTileMapSelect:
            let mask: UInt8 = 0b00001000
            
            if set {
                control |= mask
            } else {
                control &= mask ^ 0xFF
            }
        case .SpriteSize:
            let mask: UInt8 = 0b00000100
            
            if set {
                control |= mask
            } else {
                control &= mask ^ 0xFF
            }
        case .SpriteEnable:
            let mask: UInt8 = 0b00000010
            
            if set {
                control |= mask
            } else {
                control &= mask ^ 0xFF
            }
        case .BGWindowEnable:
            let mask: UInt8 = 0b00000001
            
            if set {
                control |= mask
            } else {
                control &= mask ^ 0xFF
            }
        case .LYCLYInterruptEnable:
            let mask: UInt8 = 0b01000000
            
            if set {
                status |= mask
            } else {
                status &= mask ^ 0xFF
            }
        case .Mode2InterruptEnable:
            let mask: UInt8 = 0b00100000
            
            if set {
                status |= mask
            } else {
                status &= mask ^ 0xFF
            }
        case .Mode1InterruptEnable:
            let mask: UInt8 = 0b00010000
            
            if set {
                status |= mask
            } else {
                status &= mask ^ 0xFF
            }
        case .Mode0InterruptEnable:
            let mask: UInt8 = 0b00001000
            
            if set {
                status |= mask
            } else {
                status &= mask ^ 0xFF
            }
        case .CoincidenceFlag:
            let mask: UInt8 = 0b00000100
            
            if set {
                status |= mask
            } else {
                status &= mask ^ 0xFF
            }
        }
    }
    
    public func read(flag: PPURegisterType) -> Bool {
        switch flag {
        case .LCDDisplayEnable:
            let mask: UInt8 = 0b10000000
            return control & mask == mask
        case .WindowTileMapSelect:
            let mask: UInt8 = 0b01000000
            return control & mask == mask
        case .WindowDisplayEnable:
            let mask: UInt8 = 0b00100000
            return control & mask == mask
        case .TileDataSelect:
            let mask: UInt8 = 0b00010000
            return control & mask == mask
        case .BGTileMapSelect:
            let mask: UInt8 = 0b00001000
            return control & mask == mask
        case .SpriteSize:
            let mask: UInt8 = 0b00000100
            return control & mask == mask
        case .SpriteEnable:
            let mask: UInt8 = 0b00000010
            return control & mask == mask
        case .BGWindowEnable:
            let mask: UInt8 = 0b00000001
            return control & mask == mask
        case .LYCLYInterruptEnable:
            let mask: UInt8 = 0b01000000
            return status & mask == mask
        case .Mode2InterruptEnable:
            let mask: UInt8 = 0b00100000
            return status & mask == mask
        case .Mode1InterruptEnable:
            let mask: UInt8 = 0b00010000
            return status & mask == mask
        case .Mode0InterruptEnable:
            let mask: UInt8 = 0b00001000
            return status & mask == mask
        case .CoincidenceFlag:
            let mask: UInt8 = 0b00000100
            return status & mask == mask
        }
    }
    
    
    //MARK: Tile based rendering
    
    public func createTileData() -> [Int] {
        var tiles = [Int]()
        for byte in stride(from: 0, to: memory.count, by: 16) {
            let byteArray = memory[byte..<byte+16]
            tiles.append(contentsOf: createTile(bytes: Array(byteArray)))
        }
        
        return tiles
    }
    
    public func createTileMap() -> [Int] {
        var tiles = [Int]()
        for tileNo in tilemap9800 {
            let byteArray = memory[Int(UInt16(tileNo) * 16)..<Int((UInt16(tileNo) * 16 + 16))]
            tiles.append(contentsOf: createTile(bytes: Array(byteArray)))
        }
        
        return tiles
    }
    
    public func createTile(bytes: [UInt8]) -> [Int] {
        var pixelRows = [Int]()
        
        for row in stride(from: 0, to: bytes.count, by: 2) {
            pixelRows.append(contentsOf: createPixelRow(byte1: bytes[row], byte2: bytes[row+1]))
        }
        
       return pixelRows
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
            let msb = byte2.get(bit: UInt8(bit))
            let lsb = byte1.get(bit: UInt8(bit))
            
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
}

//MARK: Internal information

enum Palette {
    case white
    case light
    case dark
    case black
}

enum PPUMode {
    case HorizontalBlank
    case VerticalBlank
    case OAM
    case Draw
}

enum PPURegisterType {
    case LCDDisplayEnable
    case WindowTileMapSelect
    case WindowDisplayEnable
    case TileDataSelect
    case BGTileMapSelect
    case SpriteSize
    case SpriteEnable
    case BGWindowEnable
    
    case LYCLYInterruptEnable
    case Mode2InterruptEnable
    case Mode1InterruptEnable
    case Mode0InterruptEnable
    case CoincidenceFlag
}
