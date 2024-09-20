//
//  PPU.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 17/9/2024.
//


struct PPU {
    var memory: [UInt8]
    var tilemap9800: [UInt8]
    var tilemap9C00: [UInt8]
    var oam: [UInt8]
    var oamBuffer: [(Int, UInt8, UInt8)]
    var oamChecked: Bool
    var oamCount: Int
    
    var viewPort: [Int]
    var tempViewPort: [Int]
    var scx: UInt8
    var scy: UInt8
    var ly: UInt8
    var mode: PPUMode
    var setVBlankInterrupt: Bool
    var setLCDInterrupt: Bool
    var lyc: UInt8
    var wy: UInt8
    var wx: UInt8
    var windowLineCounter: UInt8
    var fetchWindow: Bool
    
    private var cycles: UInt16
    private var x: Int
    private var drawn: Bool
    private var drawEnd: Int
    private var windowYSet: Bool
    
    //MARK: PPU Registers
    var control: UInt8
    var status: UInt8
    
    init() {
        memory = [UInt8](repeating: 0, count: 0x1800)
        tilemap9800 = [UInt8](repeating: 0, count: 0x400)
        tilemap9C00 = [UInt8](repeating: 0, count: 0x400)
        oam = [UInt8](repeating: 0, count: 0xA0)
        oamBuffer = [(Int, UInt8, UInt8)]()
        oamChecked = false
        oamCount = 0
        
        viewPort = [Int]()
        tempViewPort = [Int]()
        cycles = 0
        
        control = 0x00
        status = 0x80
        mode = .OAM
        
        scx = 0x00
        scy = 0x00
        
        ly = 0x00
        lyc = 0x00
        
        wx = 0x00
        wy = 0x00
        windowLineCounter = 0x00
        fetchWindow = false
        
        mode = .OAM
        
        x = 0
        drawn = false
        setVBlankInterrupt = false
        setLCDInterrupt = false
        drawEnd = 252
        windowYSet = false
    }
        
    //MARK: Line based rendering
    
    public mutating func updateGraphics(cycles: UInt16) {
        if !read(flag: .LCDDisplayEnable) {
            ly = 0
            mode = .HorizontalBlank
            write(flag: .Mode0, set: true)
            write(flag: .Mode0InterruptEnable, set: true)
            write(flag: .Mode1InterruptEnable, set: false)
            
        } else {
            self.cycles += cycles
            if ly == 144 {
                mode = .VerticalBlank
                write(flag: .Mode1, set: true)
                setVBlankInterrupt = true
                viewPort = tempViewPort
                windowLineCounter = 0x00
            } else if ly > 153 {
                mode = .OAM
                write(flag: .Mode2, set: true)
                ly = 0
                tempViewPort.removeAll()
                windowYSet = false
            }
            
            if mode != .VerticalBlank {
                if self.cycles >= 0 && self.cycles < 80 {
                    mode = .OAM
                    write(flag: .Mode2, set: true)
                    if !oamChecked {
                        if !windowYSet {
                            windowYSet = ly == wy
                        }
                        for location in stride(from: 0, to: 160, by: 4) {
                            let yPos = Int(oam[location]) - 16
                            let xPos = Int(oam[location + 1]) - 8
                            let index = oam[location + 2]
                            let attributes = oam[location + 3]
                            
                            if xPos > 0 && ly >= yPos && ly < yPos + 8 && oamCount < 10 {
                                oamBuffer.append((xPos,index, attributes))
                                oamCount += 1
                            }
                        }
                        
                        oamChecked = true
                    }
                    
                } else if self.cycles >= 80 && self.cycles < drawEnd {
                    mode = .Draw
                    write(flag: .Mode3, set: true)

                    if !drawn {
                        var x = 0
                        let remove = Int(scx % 8)
                        drawEnd += remove
                        
                        for pixel in stride(from: 0, to: 160, by: 8) {
                            if !fetchWindow { // FIXME: Don't like this. It is hacky and needs to be done better
                                fetchWindow = read(flag: .WindowDisplayEnable) && windowYSet && pixel >= wx - 7
                                x = fetchWindow ? 0 : x
                            }
                            fetchWindow = read(flag: .WindowDisplayEnable) && windowYSet && pixel >= wx - 7
                            
                            var tilemap = read(flag: .BGTileMapSelect) ? tilemap9C00 : tilemap9800
                            var fetcher = (Int(ly) + Int(scy)) & 0xFF
                            

                            if fetchWindow {
                                tilemap = read(flag: .WindowTileMapSelect) ? tilemap9C00 : tilemap9800
                                fetcher = Int(windowLineCounter)
                            }
                            

                            
                            var tilemapAddress = x + ((fetcher / 8) * 0x20)
                            
                            var tileNo = tilemap[Int(tilemapAddress)]
                            
                            var tileLocation = read(flag: .TileDataSelect) ? Int(tileNo) * 16 : 0x1000 + Int(Int8(bitPattern: tileNo)) * 16
                            tileLocation += 2 * (fetcher % 8)
                            
                            
                            let byte1 = memory[Int(tileLocation)]
                            let byte2 = memory[Int(tileLocation + 0x1)]
                            var tile = createRow(byte1: byte1, byte2: byte2)
                            
                            if x == 0 {
                                tile.removeSubrange(0..<remove)
                            }
                            
                            if !read(flag: .BGWindowEnable) {
                                tile = createRow(byte1: UInt8(), byte2: UInt8())
                            }
                            
                            for obj in oamBuffer {
                                if pixel == obj.0 {
                                    
                                    var tileLocation = Int(obj.1) * 16
                                    if obj.2.get(bit: 6) { // Y Flip
                                        tileLocation += 2 * (7 - fetcher % 8) //Flip vertical
                                    } else {
                                        tileLocation += 2 * (fetcher % 8)
                                    }
                                    
                                    
                                    let byte1 = memory[tileLocation]
                                    let byte2 = memory[tileLocation + 0x1]
                                    tile = createRow(byte1: byte1, byte2: byte2)
                                    if obj.2.get(bit: 5) {
                                        tile.reverse()
                                    }
                                    drawEnd += 6
                                }
                            }
                            
                            tempViewPort.append(contentsOf: tile)
                            x += 1
                            
                        }
                        drawn = true
                    }
                } else if self.cycles >= drawEnd && self.cycles < 456 {
                    mode = .HorizontalBlank
                    write(flag: .Mode0, set: true)
                } else {
                    ly += 1
                    write(flag: .CoincidenceFlag, set: ly == lyc)
                    if fetchWindow {
                        windowLineCounter += 1
                    }
                    if read(flag: .LYCLYInterruptEnable) {
                        setLCDInterrupt = ly == lyc
                    }
                    self.cycles = 0
                    drawEnd = 252
                    oamCount = 0
                    oamChecked = false
                    oamBuffer.removeAll()
                    drawn = false
                }
            } else {
                if self.cycles >= 456 {
                    ly += 1
                    self.cycles = 0
                }
            }
        }
    }
    
    func createRow(byte1: UInt8, byte2: UInt8) -> [Int] {
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
    
//    public mutating func fetch(cycles: UInt16) {
//        self.cycles += cycles
//
//        if mode != .VerticalBlank && self.cycles >= 0 && self.cycles < 80 {
//
//        } else if mode != .VerticalBlank && self.cycles < 289 {
//            mode = .Draw
//
//            let tilemap = read(flag: .BGTileMapSelect) ? tilemap9C00 : tilemap9800
//            if !drawn {
//                x = 0
//                for _ in stride(from: 0, to: 160, by: 8) {
//                    var fetcherX = x + (Int(scx) / 8) & 0x1F
//                    var fetcherY = (Int(ly) + Int(scy)) & 0xFF
//
//                    var tilemapAddress = x + ((fetcherY / 8) * 0x20)
//
//                    var tileNo = tilemap[Int(tilemapAddress)]
//
//                    var tileLocation = read(flag: .TileDataSelect) ? Int(tileNo) * 16 : 0x1000 + Int(Int8(bitPattern: tileNo)) * 16
//                    tileLocation += (2 * (fetcherY % 8))
//
//
//                    let byte1 = memory[Int(tileLocation)]
//                    let byte2 = memory[Int(tileLocation + 0x1)]
//                    var tile = createPixelRow(byte1: byte1, byte2: byte2)
//
//                    tempViewPort.append(contentsOf: tile)
//                    x += 1
//                }
//            }
//
//            drawn = true
//
//        } else if mode != .VerticalBlank && self.cycles < 456 {
//            mode = .HorizontalBlank
//
//        } else {
//            ly += 1
//            if ly < 144 {
//                mode = .OAM
//            } else if ly >= 144 && ly <= 153  {
//                mode = .VerticalBlank
//                setVBlankInterrupt = true
//            } else {
//                mode = .OAM
//                ly = 0
//                viewPort.removeAll()
//                viewPort = tempViewPort
//                tempViewPort.removeAll()
//            }
//
//            if self.cycles > 456 {
//                drawn = false
//                self.cycles = self.cycles - 456
//            }
//        }
//    }
//
//    public mutating func fetch() {
//        viewPort.removeAll()
//
//        for line in 0..<144 {
//            ly = UInt8(line)
//            let tilemap = read(flag: .BGTileMapSelect) ? tilemap9C00 : tilemap9800
//            var x = 0
//            for _ in stride(from: 0, to: 160, by: 8) {
//                var fetcherX = x + (Int(scx) / 8) & 0x1F
//                var fetcherY = (line + Int(scy)) & 0xFF
//
//                var tilemapAddress = x + ((fetcherY / 8) * 0x20)
//
//                var tileNo = tilemap[Int(tilemapAddress)]
//
//                var tileLocation = read(flag: .TileDataSelect) ? Int(tileNo) * 16 : 0x1000 + Int(Int8(bitPattern: tileNo)) * 16
//                tileLocation += (2 * (fetcherY % 8))
//
//
//                let byte1 = memory[Int(tileLocation)]
//                let byte2 = memory[Int(tileLocation + 0x1)]
//                var tile = createPixelRow(byte1: byte1, byte2: byte2)
//
//                viewPort.append(contentsOf: tile)
//                x += 1
//            }
//        }
//    }
    
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
        case .Mode0:
            let mask: UInt8 = 0b00000000
            
            if set {
                status |= mask
            }
        case .Mode1:
            let mask: UInt8 = 0b0000001
            
            if set {
                status |= mask
            }
        case .Mode2:
            let mask: UInt8 = 0b00000010
            
            if set {
                status |= mask
            }
        case .Mode3:
            let mask: UInt8 = 0b00000011
            
            if set {
                status |= mask
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
        case .Mode0:
            let mask: UInt8 = 0b00000000
            return status & mask == mask
        case .Mode1:
            let mask: UInt8 = 0b00000001
            return status & mask == mask
        case .Mode2:
            let mask: UInt8 = 0b00000010
            return status & mask == mask
        case .Mode3:
            let mask: UInt8 = 0b00000011
            return status & mask == mask
        }
    }
    
    
    //MARK: Tile based rendering
    
//    public func createTileData() -> [Int] {
//        var tiles = [Int]()
//        for byte in stride(from: 0, to: memory.count, by: 16) {
//            let byteArray = memory[byte..<byte+16]
//            tiles.append(contentsOf: createTile(bytes: Array(byteArray)))
//        }
//        
//        return tiles
//    }
    
//    public func createTileMap() -> [Int] {
//        var tiles = [Int]()
//        for tileNo in tilemap9800 {
//            let byteArray = memory[Int(UInt16(tileNo) * 16)..<Int((UInt16(tileNo) * 16 + 16))]
//            tiles.append(contentsOf: createTile(bytes: Array(byteArray)))
//        }
//        
//        return tiles
//    }
    
//    public func createTile(bytes: [UInt8]) -> [Int] {
//        var pixelRows = [Int]()
//        
//        for row in stride(from: 0, to: bytes.count, by: 2) {
//            pixelRows.append(contentsOf: createPixelRow(byte1: bytes[row], byte2: bytes[row+1]))
//        }
//        
//       return pixelRows
//    }
    
//    public func createTile() -> [Int] {
//        let bytes: [UInt8] = [0x3C, 0x7E, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x7E, 0x5E, 0x7E, 0x0A, 0x7C, 0x56, 0x38, 0x7C]
//        var pixelRows = [Int]()
//        
//        for row in stride(from: 0, to: bytes.count, by: 2) {
//            pixelRows.append(contentsOf: createPixelRow(byte1: bytes[row], byte2: bytes[row+1]))
//        }
//        
//       return pixelRows
//    }
}

enum PPUMode {
    case HorizontalBlank
    case VerticalBlank
    case OAM
    case Draw
}

public enum PPURegisterType {
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
    
    case Mode0
    case Mode1
    case Mode2
    case Mode3
}
