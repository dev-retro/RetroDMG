//
//  PPU.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 17/9/2024.
//
//  Game Boy PPU (Pixel Processing Unit) implementation.
//  This file implements hardware-accurate background, window, and sprite rendering for DMG mode.
//  All color and priority logic is based on the official GBDEV documentation:
//  https://gbdev.io/pandocs/
//
//  Key references:
//  - Palettes: https://gbdev.io/pandocs/Palettes.html
//  - OAM/Sprites: https://gbdev.io/pandocs/OAM.html
//  - Rendering: https://gbdev.io/pandocs/Rendering.html
//  - Tile Data: https://gbdev.io/pandocs/Tile_Data.html
//

/// The main Game Boy PPU class. Handles all LCD rendering, including background, window, and sprites.
/// Implements scanline-based rendering and all timing/priority rules per GBDEV documentation.
class PPU {
    /// Tile data (0x8000-0x97FF, 0x8800-0x97FF)
    var tileData: [UInt8]
    /// Tile maps (BG/Window)
    var tilemap9800: [UInt8]
    var tilemap9C00: [UInt8]
    /// OAM (Object Attribute Memory, 40 sprites)
    var oam: [UInt8]
    /// OAM buffer for current scanline (max 10 sprites)
    var oamBuffer: [(xPos: Int, yPos: Int, index: UInt8, attributes: UInt8, oamIndex: Int)]
    var oamChecked: Bool
    var oamCount: Int
    
    /// Palettes (see GBDEV Palettes doc)
    var bgp: UInt8
    var obp0: UInt8
    var obp1: UInt8
    
    /// Framebuffer (current and temp)
    var viewPort: [Int]
    var tempViewPort: [Int]
    /// Scroll registers
    var scx: UInt8
    var scy: UInt8
    /// Current scanline
    var ly: UInt8
    /// PPU mode (HBlank, VBlank, OAM, Draw)
    var mode: PPUMode
    /// Interrupt flags
    var setVBlankInterrupt: Bool
    var setLCDInterrupt: Bool
    /// LYC compare
    var lyc: UInt8
    /// Window position
    var wy: UInt8
    var wx: UInt8
    /// Window line counter (see GBDEV Window doc)
    var windowLineCounter: UInt8
    /// Window fetch state
    var fetchWindow: Bool
    /// DMA register
    var dma: UInt8

    // Internal state
    private var cycles: UInt16
    private var x: Int
    private var drawn: Bool
    private var drawEnd: Int
    private var windowYSet: Bool
    private var bgWindowPixels: [Int]
    private var objectPixels: [Int]
    
    // PPU Registers (LCDC/STAT)
    var control: UInt8
    var status: UInt8
    
    /// Initialize all VRAM, OAM, and registers to default values.
    init() {
        tileData = [UInt8](repeating: 0, count: 0x1800)
        tilemap9800 = [UInt8](repeating: 0, count: 0x400)
        tilemap9C00 = [UInt8](repeating: 0, count: 0x400)
        oam = [UInt8](repeating: 0, count: 0xA0)
        oamBuffer = [(Int, Int, UInt8, UInt8, Int)]()
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
    
    // MARK: - Main Rendering Loop
    /// Main PPU update function. Advances the PPU by the given number of CPU cycles.
    /// Handles all mode transitions, scanline rendering, and timing penalties (SCX, window, OBJ).
    /// Implements all background, window, and sprite rendering per GBDEV docs.
    public func updateGraphics(cycles: UInt16) {
        if !read(flag: .LCDEnable) {
            ly = 0
            self.cycles = 0
            mode = .HorizontalBlank
            write(flag: .Mode0, set: true)
            setVBlankInterrupt = false
            setLCDInterrupt = false
            windowLineCounter = 0  // Reset window line counter when LCD disabled
            windowYSet = false     // Reset window Y condition
            fetchWindow = false    // Reset window fetch state
        } else {
            self.cycles += cycles
            if ly == 144 {
                mode = .VerticalBlank
                write(flag: .Mode1, set: true)
                setVBlankInterrupt = true
                viewPort = tempViewPort
                // Window line counter is reset during VBlank according to GBDEV
                windowLineCounter = 0
            } else if ly >= 154 {
                mode = .OAM
                write(flag: .Mode2, set: true)
                ly = 0
                tempViewPort.removeAll()
                windowYSet = false
                fetchWindow = false  // Reset window state for new frame
            }
            
            if mode != .VerticalBlank {
                if self.cycles >= 0 && self.cycles < 80 {
                    mode = .OAM
                    write(flag: .Mode2, set: true)
                    let spriteHeight = read(flag: .OBJSize) ? 16 : 8
                    if !oamChecked {
                        // Window Y condition check - only at start of Mode 2, once triggered stays triggered
                        if !windowYSet && read(flag: .WindowDisplayEnable) && read(flag: .BGWindowEnable) {
                            windowYSet = ly == wy
                        }
                        for location in stride(from: 0, to: 0xA0, by: 4) {
                            let yPos = Int(oam[location]) - 16
                            let xPos = Int(oam[location + 1]) - 8
                            let index = oam[location + 2]
                            let attributes = oam[location + 3]
                            let oamIndex = location / 4  // Store original OAM index
                            
                            if xPos >= -7 && ly >= yPos && ly < yPos + spriteHeight && oamCount < 10 {
                                oamBuffer.append((xPos: xPos, yPos: yPos, index: index, attributes: attributes, oamIndex: oamIndex))
                                oamCount += 1
                            }
                        }
                        
                        oamChecked = true
                    }
                    
                } else if self.cycles >= 80 && self.cycles < drawEnd {
                    mode = .Draw
                    write(flag: .Mode3, set: true)

                    if !drawn {
                        // Initialize for scanline rendering
                        var pixelsPushed = 0
                        var fetcherX = Int(scx) / 8  // Start fetcher at correct X position
                        var currentPixel = 0
                        var windowTriggered = false
                        
                        // Apply initial SCX penalty at start of Mode 3
                        let initialScrollPenalty = Int(scx) % 8
                        if initialScrollPenalty > 0 {
                            drawEnd += initialScrollPenalty
                        }
                        
                        // Render 160 pixels for this scanline
                        while pixelsPushed < 160 {
                            // Check for window trigger during rendering
                            if !windowTriggered && 
                               read(flag: .WindowDisplayEnable) && 
                               read(flag: .BGWindowEnable) && 
                               windowYSet && 
                               currentPixel + 7 >= Int(wx) {
                                windowTriggered = true
                                fetchWindow = true
                                fetcherX = 0  // Reset fetcher X for window
                                drawEnd += 6  // Window trigger penalty
                            }
                            
                            // Determine which tilemap and coordinates to use
                            let tilemap = fetchWindow ? 
                                (read(flag: .WindowTileMapSelect) ? tilemap9C00 : tilemap9800) :
                                (read(flag: .BGTileMapSelect) ? tilemap9C00 : tilemap9800)
                            
                            let fetcherY = fetchWindow ? 
                                Int(windowLineCounter) :
                                (Int(ly) + Int(scy)) & 0xFF
                            
                            // Calculate tilemap address - wrapping fetcherX correctly
                            let tilemapAddress = (fetcherX & 0x1F) + ((fetcherY / 8) * 32)
                            let tileNo = tilemap[Int(tilemapAddress)]
                            
                            // Correct tile data addressing based on LCDC.4
                            var tileLocation: Int
                            if read(flag: .TileDataSelect) {
                                // $8000 method: unsigned addressing
                                tileLocation = Int(tileNo) * 16
                            } else {
                                // $8800 method: signed addressing, base at $9000 (0x1000 in our array)
                                let signedTileNo = Int8(bitPattern: tileNo)
                                tileLocation = 0x1000 + (Int(signedTileNo) * 16)
                            }
                            
                            tileLocation += 2 * (fetcherY % 8)
                            
                            let byte1 = tileData[tileLocation]
                            let byte2 = tileData[tileLocation + 1]
                            
                            // Create 8 pixels from this tile
                            var tilePixels: [Int]
                            var bgColorIndices: [Int] // Track original color indices for priority
                            if read(flag: .BGWindowEnable) {
                                let bgData = createRowWithIndices(byte1: byte1, byte2: byte2, isBackground: true, objectPallete1: nil)
                                tilePixels = bgData.colors
                                bgColorIndices = bgData.indices
                            } else {
                                // When BG/Window disabled, render as white
                                tilePixels = [Shade.White.rawValue, Shade.White.rawValue, Shade.White.rawValue, Shade.White.rawValue,
                                             Shade.White.rawValue, Shade.White.rawValue, Shade.White.rawValue, Shade.White.rawValue]
                                bgColorIndices = [0, 0, 0, 0, 0, 0, 0, 0] // All color index 0
                            }
                            
                            // Handle scrolling offset for first tile
                            var startPixel = 0
                            if !fetchWindow && fetcherX == (Int(scx) / 8) && pixelsPushed == 0 {
                                startPixel = Int(scx) % 8
                            }
                            
                            // Process sprites for this tile area
                            var objPixels = [Int](repeating: 0, count: 8)
                            var objPriority = [Bool](repeating: false, count: 8)
                            if read(flag: .OBJEnable) {
                                processSpritesForTile(screenStartX: currentPixel, objPixels: &objPixels, objPriority: &objPriority)
                            }
                            
                            // Mix background/window with sprites and push to viewport
                            for i in startPixel..<8 {
                                if pixelsPushed >= 160 { break }
                                
                                let bgPixel = tilePixels[i]
                                let bgColorIndex = bgColorIndices[i]
                                let objPixel = objPixels[i]
                                let objBehindBG = objPriority[i] // OBJ-to-BG Priority bit
                                
                                let finalPixel: Int
                                if objPixel == 0 {
                                    // Sprite is transparent, show background
                                    finalPixel = bgPixel
                                } else if !read(flag: .BGWindowEnable) {
                                    // BG/Window disabled, sprite shows over white background
                                    finalPixel = objPixel
                                } else {
                                    // Both BG and sprite have pixels - check priority
                                    // Priority rules from GBDEV:
                                    // - If OBJ priority bit is set (objBehindBG = true) and BG color index is 1-3, show BG
                                    // - Otherwise show OBJ
                                    if objBehindBG && bgColorIndex >= 1 && bgColorIndex <= 3 {
                                        finalPixel = bgPixel
                                    } else {
                                        finalPixel = objPixel
                                    }
                                }
                                
                                tempViewPort.append(finalPixel)
                                pixelsPushed += 1
                                currentPixel += 1
                            }
                            
                            fetcherX += 1
                        }
                        
                        drawn = true
                    }
                } else if self.cycles >= drawEnd && self.cycles < 456 {
                    mode = .HorizontalBlank
                    write(flag: .Mode0, set: true)
                } else {
                    ly += 1
                    write(flag: .CoincidenceFlag, set: ly == lyc)
                    // Window line counter only increments when window was actually rendered
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
                    fetchWindow = false  // Reset fetchWindow for next scanline
                }
            } else {
                if self.cycles >= 456 {
                    ly += 1
                    self.cycles = 0
                }
            }
        }
    }
    
    /// Scanline sprite fetch. Fills oamBuffer with up to 10 sprites for the current scanline.
    /// Implements OAM scan rules per GBDEV (Y/X range, 8x8/8x16, OAM order priority).
    ///
    /// - Parameters:
    ///   - screenStartX: The X position of the first pixel in this tile (0-159)
    ///   - objPixels: Output array of sprite pixel colors (0=transparent)
    ///   - objPriority: Output array of OBJ-to-BG priority bits (true=BG priority)
    func processSpritesForTile(screenStartX: Int, objPixels: inout [Int], objPriority: inout [Bool]) {
        // Process all sprites for this 8-pixel tile area
        for i in 0..<8 {
            let screenX = screenStartX + i
            
            // Find all sprites that contain this pixel
            let spritesAtPixel = oamBuffer.filter { sprite in
                screenX >= sprite.xPos && screenX < sprite.xPos + 8
            }
            
            // Apply Game Boy sprite priority rules:
            // 1. Lowest X coordinate wins
            // 2. If X coordinates equal, first in OAM wins (lowest OAM index)
            var selectedSprite: (xPos: Int, yPos: Int, index: UInt8, attributes: UInt8, oamIndex: Int)?
            for sprite in spritesAtPixel {
                if selectedSprite == nil || 
                   sprite.xPos < selectedSprite!.xPos || 
                   (sprite.xPos == selectedSprite!.xPos && sprite.oamIndex < selectedSprite!.oamIndex) {
                    selectedSprite = sprite
                }
            }
            
            if let sprite = selectedSprite {
                let spriteHeight = read(flag: .OBJSize) ? 16 : 8
                var spriteIndex = sprite.index
                
                // Handle 8x16 sprite tile selection
                if spriteHeight == 16 {
                    let spriteY = Int(ly) - sprite.yPos
                    let isYFlipped = sprite.attributes.get(bit: 6)
                    
                    // For 8x16 sprites, hardware ignores LSB of tile index
                    let baseTileIndex = sprite.index & 0xFE
                    
                    // Determine which 8x8 tile within the 8x16 sprite we're rendering
                    let tileRow = isYFlipped ? (spriteY >= 8 ? 0 : 1) : (spriteY >= 8 ? 1 : 0)
                    spriteIndex = baseTileIndex + UInt8(tileRow)
                }
                
                // Calculate tile location
                var tileLocation = Int(spriteIndex) * 16
                let spriteY = Int(ly) - sprite.yPos
                let lineInTile = spriteY % 8
                let actualLineInTile = sprite.attributes.get(bit: 6) ? (7 - lineInTile) : lineInTile
                tileLocation += 2 * actualLineInTile
                
                // Get sprite tile data
                let byte1 = tileData[tileLocation]
                let byte2 = tileData[tileLocation + 1]
                
                // Calculate pixel within sprite (bounds check)
                let spritePixelX = screenX - sprite.xPos
                if spritePixelX < 0 || spritePixelX >= 8 {
                    continue // Skip if pixel is outside sprite bounds
                }
                
                let actualSpritePixelX = sprite.attributes.get(bit: 5) ? (7 - spritePixelX) : spritePixelX // X flip
                
                // Extract color index for this pixel
                // Bit 7 = leftmost pixel, bit 0 = rightmost pixel
                let bitIndex = 7 - actualSpritePixelX
                if bitIndex < 0 || bitIndex > 7 {
                    continue // Skip invalid bit index
                }
                
                let lsb = byte1.get(bit: UInt8(bitIndex))  // First byte is LSB
                let msb = byte2.get(bit: UInt8(bitIndex))  // Second byte is MSB
                let colorIndex = (msb ? 2 : 0) + (lsb ? 1 : 0)
                
                // Only render non-transparent pixels
                if colorIndex != 0 {
                    let palette = sprite.attributes.get(bit: 4) ? obp1 : obp0
                    let shadeValue = shadeForColorIndex(colorIndex, palette: palette)
                    
                    objPixels[i] = shadeValue.rawValue
                    objPriority[i] = sprite.attributes.get(bit: 7) // OBJ-to-BG Priority
                }
            }
        }
    }
    
    /// Returns the Shade for a given color index (0-3) and palette byte (BGP/OBP0/OBP1).
    /// Implements the mapping described in GBDEV Palettes doc.
    /// - Parameters:
    ///   - colorIndex: The color index (0-3) from tile data
    ///   - palette: The palette register (BGP, OBP0, OBP1)
    /// - Returns: The mapped Shade (White, LightGray, DarkGray, Black)
    func shadeForColorIndex(_ colorIndex: Int, palette: UInt8) -> Shade {
        let paletteBits = (palette >> (colorIndex * 2)) & 0x03
        switch paletteBits {
        case 0: return .White
        case 1: return .LightGray
        case 2: return .DarkGray
        case 3: return .Black
        default: return .White
        }
    }

    /// Creates a row of 8 pixels from tile data, mapping through the palette.
    /// For background, all color indices are mapped. For sprites, color 0 is transparent.
    /// - Parameters:
    ///   - byte1, byte2: Tile data bytes
    ///   - isBackground: True for BG/Window, false for OBJ
    ///   - objectPallete1: For sprites, true=OBP1, false=OBP0
    /// - Returns: Array of 8 pixel shades (as Ints)
    func createRow(byte1: UInt8, byte2: UInt8, isBackground: Bool, objectPallete1: Bool?) -> [Int] {
        var colourIds = [Int](repeating: 0, count: 8)
        let palette = isBackground ? bgp : (objectPallete1! ? obp1 : obp0)
        for bit in 0..<8 {
            let bitIndex = 7 - bit
            let lsb = byte1.get(bit: UInt8(bitIndex))
            let msb = byte2.get(bit: UInt8(bitIndex))
            let colorIndex = (msb ? 2 : 0) + (lsb ? 1 : 0)
            if !isBackground && colorIndex == 0 {
                colourIds[bit] = 0 // Transparent for sprites
            } else {
                colourIds[bit] = shadeForColorIndex(colorIndex, palette: palette).rawValue
            }
        }
        return colourIds
    }

    /// Like createRow, but also returns the original color indices (0-3) for each pixel.
    /// Used for correct OBJ-to-BG priority logic (see GBDEV OAM doc).
    /// - Returns: Tuple of ([shades], [indices])
    func createRowWithIndices(byte1: UInt8, byte2: UInt8, isBackground: Bool, objectPallete1: Bool?) -> (colors: [Int], indices: [Int]) {
        var colourIds = [Int](repeating: 0, count: 8)
        var colorIndices = [Int](repeating: 0, count: 8)
        let palette = isBackground ? bgp : (objectPallete1! ? obp1 : obp0)
        for bit in 0..<8 {
            let bitIndex = 7 - bit
            let lsb = byte1.get(bit: UInt8(bitIndex))
            let msb = byte2.get(bit: UInt8(bitIndex))
            let colorIndex = (msb ? 2 : 0) + (lsb ? 1 : 0)
            colorIndices[bit] = colorIndex
            if !isBackground && colorIndex == 0 {
                colourIds[bit] = 0 // Transparent for sprites
            } else {
                colourIds[bit] = shadeForColorIndex(colorIndex, palette: palette).rawValue
            }
        }
        return (colors: colourIds, indices: colorIndices)
    }
    
    /// Deprecated. Old pixel mixing logic, not used in new renderer.
    func comparePixels(BGOBJPriority: Bool, horizontalFlip: Bool, tileCount: Int) -> [Int] {
        // This function is now deprecated in the new pixel-by-pixel rendering
        // Keeping for compatibility but should not be called
        return []
    }
    

    /// Write PPU mode (HBlank, VBlank, OAM, Draw)
    func write(mode: PPUMode) {
        self.mode = mode
    }
    
    /// Read current PPU mode
    public func readMode() -> PPUMode {
        return mode
    }
    
    /// Set or clear a PPU register flag (LCDC/STAT)
    public func write(flag: PPURegisterType, set: Bool) {
        switch flag {
        case .LCDEnable:
            control.set(bit: 7, value: set)
        case .WindowTileMapSelect:
            control.set(bit: 6, value: set)
        case .WindowDisplayEnable:
            control.set(bit: 5, value: set)
        case .TileDataSelect:
            control.set(bit: 4, value: set)
        case .BGTileMapSelect:
            control.set(bit: 3, value: set)
        case .OBJSize:
            control.set(bit: 2, value: set)
        case .OBJEnable:
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
    
    /// Read a PPU register flag (LCDC/STAT)
    public func read(flag: PPURegisterType) -> Bool {
        switch flag {
        case .LCDEnable:
            return control.get(bit: 7)
        case .WindowTileMapSelect:
            return control.get(bit: 6)
        case .WindowDisplayEnable:
            return control.get(bit: 5)
        case .TileDataSelect:
            return control.get(bit: 4)
        case .BGTileMapSelect:
            return control.get(bit: 3)
        case .OBJSize:
            return control.get(bit: 2)
        case .OBJEnable:
            return control.get(bit: 1)
        case .BGWindowEnable:
            return control.get(bit: 0)
            
        case .LYCLYInterruptEnable:
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

/// PPU modes (see GBDEV Rendering doc)
enum PPUMode {
    case HorizontalBlank
    case VerticalBlank
    case OAM
    case Draw
}

/// Game Boy DMG shade values (see GBDEV Palettes doc)
enum Shade: Int {
    case White = 0
    case LightGray = 1
    case DarkGray = 2
    case Black = 3
}

/// PPU register flags for LCDC/STAT (see GBDEV docs)
public enum PPURegisterType {
    // Control
    case LCDEnable
    case WindowTileMapSelect
    case WindowDisplayEnable
    case TileDataSelect
    case BGTileMapSelect
    case OBJSize
    case OBJEnable
    case BGWindowEnable

    // Status
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