//
//  PPU.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 17/9/2024.
//


class PPU {
    var memory: [UInt8]
    var tilemap9800: [UInt8]
    var tilemap9C00: [UInt8]
    var oam: [UInt8]
    var oamBuffer: [(xPos: Int, yPos: Int, index: UInt8, attributes: UInt8)]
    var oamChecked: Bool
    var oamCount: Int
    
    
    ///Pallets
    var bgp: UInt8
    var obp0: UInt8
    var obp1: UInt8
    
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
    var dma: UInt8
    
    private var cycles: UInt16
    private var x: Int
    private var drawn: Bool
    private var drawEnd: Int
    private var windowYSet: Bool
    private var bgWindowPixels: [Int]
    private var objectPixels: [Int]
    
    //MARK: PPU Registers
    var control: UInt8
    var status: UInt8
    
    init() {
        memory = [UInt8](repeating: 0, count: 0x1800)
        tilemap9800 = [UInt8](repeating: 0, count: 0x400)
        tilemap9C00 = [UInt8](repeating: 0, count: 0x400)
        oam = [UInt8](repeating: 0, count: 0xA0)
        oamBuffer = [(Int, Int, UInt8, UInt8)]()
        oamChecked = false
        oamCount = 0
        
        bgp = 0x00
        obp0 = 0x00
        obp1 = 0x00
        
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
        dma = 0
        
        mode = .OAM
        
        x = 0
        drawn = false
        setVBlankInterrupt = false
        setLCDInterrupt = false
        drawEnd = 252
        windowYSet = false
        bgWindowPixels = [Int]()
        objectPixels = [Int]()
    }
        
    //MARK: Line based rendering
    
    public func updateGraphics(cycles: UInt16) {
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
                write(flag: .Mode1InterruptEnable, set: true)
                setLCDInterrupt = true
                setVBlankInterrupt = true
                viewPort = tempViewPort
                windowLineCounter = 0x00
            } else if ly > 153 {
                mode = .OAM
                write(flag: .Mode2, set: true)
                write(flag: .Mode2InterruptEnable, set: true)
                setLCDInterrupt = true
                ly = 0
                tempViewPort.removeAll()
                windowYSet = false
            }
            
            if mode != .VerticalBlank {
                if self.cycles >= 0 && self.cycles < 80 {
                    mode = .OAM
                    write(flag: .Mode2, set: true)
                    write(flag: .Mode2InterruptEnable, set: true)
                    setLCDInterrupt = true
                    let spriteHeight = read(flag: .SpriteSize) ? 16 : 8
                    if !oamChecked {
                        if !windowYSet {
                            windowYSet = ly == wy
                        }
                        for location in stride(from: 0, to: 160, by: 4) {
                            let yPos = Int(oam[location]) - 16
                            let xPos = Int(oam[location + 1]) - 8
                            let index = oam[location + 2]
                            let attributes = oam[location + 3]
                            
                            if xPos > 0 && ly >= yPos && ly < yPos + spriteHeight && oamCount < 10 {
                                oamBuffer.append((xPos: xPos, yPos: yPos, index: index, attributes))
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
                        
                        for pixel in stride(from: 0, to: scx != 0 ? 168 : 160, by: 8) {
                            if !fetchWindow { // FIXME: Don't like this. It is hacky and needs to be done better
                                fetchWindow = read(flag: .WindowDisplayEnable) && windowYSet && pixel >= wx - 7
                                x = fetchWindow ? 0 : x
                            }
                            
                            if pixel == 0 {
                                drawEnd += Int(scx) % 8
                            }
                            fetchWindow = read(flag: .WindowDisplayEnable) && windowYSet && pixel >= wx - 7
                            
                            var tilemap = read(flag: .BGTileMapSelect) ? tilemap9C00 : tilemap9800
                            var fetcherY = 0
                            var fetcherX = 0
                            

                            if fetchWindow {
                                drawEnd += 6
                                tilemap = read(flag: .WindowTileMapSelect) ? tilemap9C00 : tilemap9800
                                fetcherY = Int(windowLineCounter)
                                fetcherX = x
                            } else {
                                fetcherY = ((Int(ly) + Int(scy)) & 0xFF)
                                fetcherX = (x + (Int(scx) / 8)) & 0x1F
                            }
                            

                            
                            let tilemapAddress = fetcherX + ((fetcherY / 8) * 32)
                            
                            let tileNo = tilemap[Int(tilemapAddress)]
                            
                            
                            var tileLocation = read(flag: .TileDataSelect) ? Int(tileNo) * 16 : 0x1000 + Int(Int8(bitPattern: tileNo)) * 16
                            tileLocation += 2 * (fetcherY % 8)
                            
                            
                            let byte1 = memory[tileLocation]
                            let byte2 = memory[tileLocation + 0x1]
                            bgWindowPixels = createRow(byte1: byte1, byte2: byte2, isBackground: true, objectPallete1: nil)
                            
                            
                            if !read(flag: .BGWindowEnable) {
                                bgWindowPixels = createRow(byte1: UInt8(), byte2: UInt8(), isBackground: true, objectPallete1: nil)
                            }
                            
                            
                            
                            
                            // MARK: Sprite rendering
                            var bgObjPriority = false
                            var horizontalFlip = false
                            var objPixelHolder = [Int]()
                            
                            
                            
                            if read(flag: .SpriteEnable) {
                                let objects = oamBuffer.filter { $0.xPos >= pixel && $0.xPos < pixel + 8 }
                                var object: (xPos: Int, yPos: Int, index: UInt8, attributes: UInt8)?
                                for objectToCheck in objects {
                                    object = object == nil ? objectToCheck : objectToCheck.xPos < object!.xPos ? objectToCheck : object
                                }
                                
                                if var object {
                                    let spriteHeight = read(flag: .SpriteSize) ? 16 : 8
                                    
                                    if spriteHeight == 16 && Int(ly) - object.yPos < 8 {
                                        object.index.set(bit: 0, value: object.attributes.get(bit: 6) ? true : false)
                                    } else if spriteHeight == 16 {
                                        object.index.set(bit: 0, value: object.attributes.get(bit: 6) ? false : true)
                                    }
                                    
                                    var tileLocation = Int(object.index) * 16
                                    if object.attributes.get(bit: 6) { // Y Flip
                                        tileLocation += 2 * (7 - fetcherY % 8) //Flip vertical
                                    } else {
                                        tileLocation += 2 * (fetcherY % 8)
                                    }
                                    
                                    bgObjPriority = object.attributes.get(bit: 7)
                                    
                                    horizontalFlip = object.attributes.get(bit: 5)
                                    
                                    let byte1 = memory[tileLocation]
                                    let byte2 = memory[tileLocation + 0x1]
                                    
                                    let offset = object.xPos - pixel
                                    
                                    let row = createRow(byte1: byte1, byte2: byte2, isBackground: false, objectPallete1: object.attributes.get(bit: 4))
                                    

                                    
                                    if horizontalFlip {
                                        objPixelHolder.append(contentsOf: row)
                                        objPixelHolder.append(contentsOf: [Int](repeating: 0, count: offset))
                                    } else {
                                        objPixelHolder.append(contentsOf: [Int](repeating: 0, count: offset))
                                        objPixelHolder.append(contentsOf: row)
                                        objPixelHolder.removeLast(offset)
                                    }
                                    
                                    drawEnd += 6
                                }
                            }
                            
                            objectPixels.append(contentsOf: objPixelHolder)
                            objPixelHolder.removeAll()
                            
                            let pixelsToAppend = comparePixels(BGOBJPriority: bgObjPriority, horizontalFlip: horizontalFlip, tileCount: x)
                            
                            tempViewPort.append(contentsOf: pixelsToAppend)
                            
                            x += 1
                            
                        }
                        drawn = true
                    }
                } else if self.cycles >= drawEnd && self.cycles < 456 {
                    mode = .HorizontalBlank
                    write(flag: .Mode0, set: true)
                    write(flag: .Mode0InterruptEnable, set: true)
                    setLCDInterrupt = true
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
                    bgWindowPixels.removeAll()
                    objectPixels.removeAll()
                }
            } else {
                if self.cycles >= 456 {
                    ly += 1
                    self.cycles = 0
                }
            }
        }
    }
    
    func createRow(byte1: UInt8, byte2: UInt8, isBackground: Bool, objectPallete1: Bool?) -> [Int] {
        var colourIds = [Int](repeating: 0, count: 8)
        
        var ids = [Shade.White, Shade.LightGray, Shade.DarkGray, Shade.Black]

        for bit in 0..<8 {
            let msb = byte2.get(bit: UInt8(bit))
            let lsb = byte1.get(bit: UInt8(bit))
            

            let pallete = isBackground ? bgp : objectPallete1! ? obp1 : obp0
            
            for palleteBit in stride(from: isBackground ? 0 : 2, to: 8, by: 2) {
                if pallete.get(bit: UInt8(palleteBit + 1)) {
                    if pallete.get(bit: UInt8(palleteBit)) {
                        ids[palleteBit / 2] = Shade.Black
                    } else {
                        ids[palleteBit / 2] = Shade.DarkGray
                    }
                } else {
                    if pallete.get(bit: UInt8(palleteBit)) {
                        ids[palleteBit / 2] = Shade.LightGray
                    } else {
                        ids[palleteBit / 2] = Shade.White
                    }
                }
            }
            
            if msb {
                if lsb {
                    colourIds[7-bit] = ids[3].rawValue
                } else {
                    colourIds[7-bit] = ids[2].rawValue
                }
            } else {
                if lsb {
                    colourIds[7-bit] = ids[1].rawValue
                } else {
                    colourIds[7-bit] = ids[0].rawValue
                }
            }
        }

        return colourIds
    }
    
    func comparePixels(BGOBJPriority: Bool, horizontalFlip: Bool, tileCount: Int) -> [Int] {
        var pixels = [Int]()
        var pixelsToDiscard = Int(scx) % 8
        
        if horizontalFlip {
            objectPixels.reverse()
        }
        
        let pixelCount = tileCount == 20 ? pixelsToDiscard : bgWindowPixels.count
        
        for _ in 0..<pixelCount {
            let ObjPixel = !objectPixels.isEmpty ? objectPixels.removeFirst() : 0
            let BGWinPixel = bgWindowPixels.removeFirst()
            
            if tileCount == 0 && pixelsToDiscard > 0 {
                pixelsToDiscard -= 1
                continue
            }
            
            if ObjPixel == 0 {
                pixels.append(BGWinPixel)
            } else if BGOBJPriority && BGWinPixel != 0 {
                pixels.append(BGWinPixel)
            } else {
                pixels.append(ObjPixel)
            }
        }
        
        bgWindowPixels.removeAll()
        
        return pixels
    }
    

    func write(mode: PPUMode) {
        self.mode = mode
    }
    
    public func readMode() -> PPUMode {
        return mode
    }
    
    public func write(flag: PPURegisterType, set: Bool) {
        switch flag {
        case .LCDDisplayEnable:
            control.set(bit: 7, value: set)
        case .WindowTileMapSelect:
            control.set(bit: 6, value: set)
        case .WindowDisplayEnable:
            control.set(bit: 5, value: set)
        case .TileDataSelect:
            control.set(bit: 4, value: set)
        case .BGTileMapSelect:
            control.set(bit: 3, value: set)
        case .SpriteSize:
            control.set(bit: 2, value: set)
        case .SpriteEnable:
            control.set(bit: 1, value: set)
        case .BGWindowEnable:
            control.set(bit: 0, value: set)
        case .LYCLYInterruptEnable:
            status.set(bit: 6, value: set)
        case .Mode2InterruptEnable:
            status.set(bit: 5, value: set)
        case .Mode1InterruptEnable:
            status.set(bit: 4, value: set)
        case .Mode0InterruptEnable:
            status.set(bit: 3, value: set)
        case .CoincidenceFlag:
            status.set(bit: 2, value: set)
        case .Mode0:
            if set {
                status.set(bit: 0, value: false)
                status.set(bit: 1, value: false)
            }
        case .Mode1:
            if set {
                status.set(bit: 0, value: true)
                status.set(bit: 1, value: false)
            }
        case .Mode2:
            if set {
                status.set(bit: 0, value: false)
                status.set(bit: 1, value: true)
            }
        case .Mode3:
            if set {
                status.set(bit: 0, value: true)
                status.set(bit: 1, value: true)
            }
        }
    }
    
    public func read(flag: PPURegisterType) -> Bool {
        switch flag {
        case .LCDDisplayEnable:
            return control.get(bit: 7)
        case .WindowTileMapSelect:
            return control.get(bit: 6)
        case .WindowDisplayEnable:
            return control.get(bit: 5)
        case .TileDataSelect:
            return control.get(bit: 4)
        case .BGTileMapSelect:
            return control.get(bit: 3)
        case .SpriteSize:
            return control.get(bit: 2)
        case .SpriteEnable:
            return control.get(bit: 1)
        case .BGWindowEnable:
            return control.get(bit: 0)
            
        case .LYCLYInterruptEnable:
            let mask: UInt8 = 0b01000000
            return status.get(bit: 6)
        case .Mode2InterruptEnable:
            return status.get(bit: 5)
        case .Mode1InterruptEnable:
            return status.get(bit: 4)
        case .Mode0InterruptEnable:
            return status.get(bit: 3)
        case .CoincidenceFlag:
            return status.get(bit: 2)
        case .Mode0:
            return !status.get(bit: 0) && !status.get(bit: 1)
        case .Mode1:
            return status.get(bit: 0) && !status.get(bit: 1)
        case .Mode2:
            return !status.get(bit: 0) && status.get(bit: 1)
        case .Mode3:
            return status.get(bit: 0) && status.get(bit: 1)
        }
    }
}

enum Shade: Int {
    case White = 0
    case LightGray = 1
    case DarkGray = 2
    case Black = 3
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
