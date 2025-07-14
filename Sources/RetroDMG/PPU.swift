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
    /// Shadow VRAM arrays for tile data and tilemaps
    var tileData: [UInt8] = [UInt8](repeating: 0, count: 0x1800) // 0x8000-0x97FF
    var tilemap9800: [UInt8] = [UInt8](repeating: 0, count: 0x400) // 0x9800-0x9BFF
    var tilemap9C00: [UInt8] = [UInt8](repeating: 0, count: 0x400) // 0x9C00-0x9FFF
    /// Debug flag (should be set from CPU debug option)
    var debugEnabled: Bool = false
    /// Reference to system bus for VRAM access
    weak var bus: Bus?
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
    
    // --- FIFO Implementation ---
    /// Pixel FIFO entry for BG/OBJ
    struct PixelFIFOEntry {
        var colorIndex: Int      // 0-3
        var palette: UInt8       // Palette register value at fetch time
        var isSprite: Bool       // True if OBJ pixel
        var objPriority: Bool    // OBJ-to-BG priority bit (sprites only)
        var objPalette1: Bool?   // true=OBP1, false=OBP0 (sprites only)
    }

    /// BG/Window pixel FIFO (max 16 entries, but usually 8-10)
    var bgFIFO: [PixelFIFOEntry]
    /// OBJ pixel FIFO (same length as BG FIFO)
    var objFIFO: [PixelFIFOEntry]

    /// Reset FIFOs for new scanline
    func resetFIFOs() {
        bgFIFO.removeAll(keepingCapacity: true)
        objFIFO.removeAll(keepingCapacity: true)
    }

    /// Push BG pixels into FIFO (called after tile fetch)
    /// Per Pandocs: pixels only pushed if FIFO has less than 8 pixels
    func pushBGToFIFO(indices: [Int], palette: UInt8) {
        guard bgFIFO.count <= 8 else { return }  // Only push if FIFO has space
        bgFIFO.append(contentsOf: indices.map { idx in
            PixelFIFOEntry(colorIndex: idx, palette: palette, isSprite: false, objPriority: false, objPalette1: nil)
        })
    }

    /// Push OBJ pixels into FIFO (called after sprite fetch)
    /// Per Pandocs: mix sprite pixels with existing background
    func pushOBJToFIFO(indices: [Int], palettes: [UInt8], priority: [Bool], palette1: [Bool]) {
        // Ensure OBJ FIFO has at least as many entries as we're trying to mix
        while objFIFO.count < indices.count {
            objFIFO.append(PixelFIFOEntry(colorIndex: 0, palette: 0, isSprite: true, objPriority: false, objPalette1: false))
        }

        // For each pixel, only allow the first non-transparent sprite pixel (in OAM order) to be used
        for i in 0..<indices.count {
            let incomingTransparent = indices[i] == 0
            let existingTransparent = objFIFO[i].colorIndex == 0
            // Only overwrite if existing is transparent and incoming is non-transparent
            if existingTransparent && !incomingTransparent {
                objFIFO[i] = PixelFIFOEntry(colorIndex: indices[i], palette: palettes[i], isSprite: true, objPriority: priority[i], objPalette1: palette1[i])
            }
            // If existing is non-transparent, do not overwrite (higher-priority sprite already present)
        }
    }

    /// Pop one pixel from each FIFO, mix, and return final shade
    /// Per Pandocs: only pop when both FIFOs have pixels ready
    func popAndMixPixel(x: Int) -> Int? {
        guard !bgFIFO.isEmpty else { return nil }

        let bgPixel = bgFIFO.removeFirst()
        let objPixel = objFIFO.isEmpty ? nil : objFIFO.removeFirst()

        // Sprite colorIndex 0 is always transparent: BG shows through
        if let obj = objPixel, read(flag: .OBJEnable) {
            if obj.colorIndex == 0 {
                // Transparent sprite pixel, show BG
                return shadeForColorIndex(bgPixel.colorIndex, palette: bgPixel.palette).rawValue
            }
            // Sprite pixel is visible, check priority
            if obj.objPriority && bgPixel.colorIndex != 0 {
                // BG has priority over sprite (unless BG is color 0)
                return shadeForColorIndex(bgPixel.colorIndex, palette: bgPixel.palette).rawValue
            } else {
                // Sprite has priority or BG is color 0
                let spriteColor = shadeForColorIndex(obj.colorIndex, palette: obj.palette).rawValue
                return spriteColor
            }
        } else {
            // No sprite pixel or sprite disabled, show background
            return shadeForColorIndex(bgPixel.colorIndex, palette: bgPixel.palette).rawValue
        }
    }

    /// Double-buffered framebuffers
    /// viewPort: 160x144 (displayed frame), tempFrameBuffer: 160x144 (frame being rendered)
    var viewPort: [Int]   // 160*144 - Current displayed frame
    var tempFrameBuffer: [Int] // 160*144 - Frame being rendered
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
    private var drawn: Bool
    private var drawEnd: Int
    private var windowYSet: Bool
    
    // PPU Registers (LCDC/STAT)
    var control: UInt8
    var status: UInt8
    
    /// Initialize all OAM, registers, and state. Bus must be set after init.
    init() {
        oam = [UInt8](repeating: 0, count: 0xA0)
        oamBuffer = [(Int, Int, UInt8, UInt8, Int)]()
        oamChecked = false
        oamCount = 0
        bgp = 0x00
        obp0 = 0x00
        obp1 = 0x00
        bgFIFO = [PixelFIFOEntry]()
        objFIFO = [PixelFIFOEntry]()
        viewPort = [Int](repeating: 0, count: 160*144)
        tempFrameBuffer = [Int](repeating: 0, count: 160*144)
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
        drawn = false
        setVBlankInterrupt = false
        setLCDInterrupt = false
        drawEnd = 252
        windowYSet = false
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
                // Swap framebuffers: copy completed frame to display buffer
                viewPort = tempFrameBuffer
                windowLineCounter = 0
            } else if ly >= 154 {
                mode = .OAM
                write(flag: .Mode2, set: true)
                ly = 0
                // Clear temp framebuffer for new frame rendering
                tempFrameBuffer = [Int](repeating: 0, count: 160*144)
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
                        // Hardware: scan OAM in order, add first 10 sprites that intersect scanline, regardless of X position
                        for location in stride(from: 0, to: 0xA0, by: 4) {
                            if oamCount >= 10 { break }
                            let yPos = Int(oam[location]) - 16
                            let xPos = Int(oam[location + 1]) - 8
                            let index = oam[location + 2]
                            let attributes = oam[location + 3]
                            let oamIndex = location / 4  // Store original OAM index

                            // Sprite intersects scanline (Y range), do not filter by X
                            if ly >= yPos && ly < yPos + spriteHeight {
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
                        var fetcherX = 0  // Always start at tile 0, handle SCX offset below
                        var windowTriggered = false
                        
                        // Clear FIFOs at start of Mode 3 (per Pandocs)
                        resetFIFOs()
                        
                        // Calculate scanline offset in framebuffer
                        let scanlineOffset = Int(ly) * 160
                        let scxOffset = Int(scx) % 8
                        // Render 160 pixels for this scanline
                        var scxDiscarded = false
                        while pixelsPushed < 160 {
                            // Window trigger check (per Pandocs: trigger when WX-7 reached)
                            if !windowTriggered && 
                               read(flag: .WindowDisplayEnable) && 
                               read(flag: .BGWindowEnable) && 
                               windowYSet && 
                               pixelsPushed >= Int(wx) - 7 {
                                windowTriggered = true
                                fetchWindow = true
                                fetcherX = 0
                                // Clear background FIFO when window starts (per Pandocs)
                                bgFIFO.removeAll(keepingCapacity: true)
                                drawEnd += 6  // Window penalty
                            }

                            // Only fetch new tile data if FIFO needs it
                            if bgFIFO.count < 8 {
                                let tilemap = (fetchWindow ? (read(flag: .WindowTileMapSelect) ? tilemap9C00 : tilemap9800)
                                                          : (read(flag: .BGTileMapSelect) ? tilemap9C00 : tilemap9800))
                                let fetcherY = fetchWindow ? Int(windowLineCounter) : (Int(ly) + Int(scy)) & 0xFF
                                let scxTileOffset = Int(scx) / 8
                                let tilemapX = fetchWindow ? fetcherX : (scxTileOffset + fetcherX) & 0x1F
                                let tilemapAddress = tilemapX + ((fetcherY / 8) * 32)
                                let tileNo = tilemap[Int(tilemapAddress)]
                                var tileLocation: Int
                                if read(flag: .TileDataSelect) {
                                    tileLocation = Int(tileNo) * 16
                                } else {
                                    let signedTileNo = Int8(bitPattern: tileNo)
                                    tileLocation = 0x1000 + (Int(signedTileNo) * 16)
                                }
                                tileLocation += 2 * (fetcherY % 8)
                                let byte1 = tileData[tileLocation]
                                let byte2 = tileData[tileLocation + 1]
                                var bgColorIndices: [Int]
                                if read(flag: .BGWindowEnable) {
                                    let bgData = createRowWithIndices(byte1: byte1, byte2: byte2, isBackground: true, objectPallete1: nil)
                                    bgColorIndices = bgData.indices
                                } else {
                                    bgColorIndices = [Int](repeating: 0, count: 8)
                                }
                                // Push to BG FIFO
                                pushBGToFIFO(indices: bgColorIndices, palette: bgp)
                                fetcherX += 1
                            }

                            // Pop and output pixels if FIFO has enough data
                            if bgFIFO.count >= 8 {
                                // Handle SCX scroll offset for first tile, only once per scanline
                                if !fetchWindow && !scxDiscarded {
                                    for _ in 0..<scxOffset {
                                        if !bgFIFO.isEmpty {
                                            _ = bgFIFO.removeFirst()
                                        }
                                        if !objFIFO.isEmpty {
                                            _ = objFIFO.removeFirst()
                                        }
                                    }
                                    scxDiscarded = true
                                }

                                // Handle sprites for current pixel position
                                var objPixels = [Int](repeating: 0, count: 8)
                                var objPriority = [Bool](repeating: false, count: 8)
                                var objPalette1 = [Bool](repeating: false, count: 8)
                                if read(flag: .OBJEnable) {
                                    processSpritesForTile(screenStartX: pixelsPushed, objPixels: &objPixels, objPriority: &objPriority, objPalette1: &objPalette1)
                                    var objPalettes: [UInt8] = []
                                    for j in 0..<8 {
                                        objPalettes.append(objPalette1[j] ? obp1 : obp0)
                                    }
                                    pushOBJToFIFO(indices: objPixels, palettes: objPalettes, priority: objPriority, palette1: objPalette1)
                                } else {
                                    // Sprites disabled, fill with transparent pixels
                                    objPixels = [Int](repeating: 0, count: 8)
                                    objPriority = [Bool](repeating: false, count: 8)
                                    objPalette1 = [Bool](repeating: false, count: 8)
                                }

                                // Output one pixel directly to framebuffer
                                if let finalPixel = popAndMixPixel(x: pixelsPushed) {
                                    tempFrameBuffer[scanlineOffset + pixelsPushed] = finalPixel
                                } else {
                                    tempFrameBuffer[scanlineOffset + pixelsPushed] = 0  // White fallback
                                }
                                pixelsPushed += 1
                            }
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
    /// Scanline sprite fetch. Fills oamBuffer with up to 10 sprites for the current scanline.
    /// Implements OAM scan rules per GBDEV (Y/X range, 8x8/8x16, OAM order priority).
    ///
    /// - Parameters:
    ///   - screenStartX: The X position of the first pixel in this tile (0-159)
    ///   - objPixels: Output array of sprite pixel color indices (0=transparent, 1-3=opaque)
    ///   - objPriority: Output array of OBJ-to-BG priority bits (true=BG priority)
    ///   - objPalette1: Output array of per-pixel palette select (true=OBP1, false=OBP0)
    func processSpritesForTile(screenStartX: Int, objPixels: inout [Int], objPriority: inout [Bool], objPalette1: inout [Bool]) {
        for i in 0..<8 {
            let screenX = screenStartX + i
            for sprite in oamBuffer {
                // Accept sprites with X between -7 and 159 (partially or fully visible)
                if screenX >= sprite.xPos && screenX < sprite.xPos + 8 {
                    let spriteHeight = read(flag: .OBJSize) ? 16 : 8
                    var spriteIndex = sprite.index
                    let spriteY = Int(ly) - sprite.yPos

                    if spriteHeight == 16 {
                        let baseTileIndex = sprite.index & 0xFE
                        spriteIndex = baseTileIndex + UInt8(spriteY >= 8 ? 1 : 0)
                    }

                    var tileLocation = Int(spriteIndex) * 16
                    let lineInTile = spriteY % 8
                    let actualLineInTile = sprite.attributes.get(bit: 6) ? (7 - lineInTile) : lineInTile
                    tileLocation += 2 * actualLineInTile
                    let byte1 = tileData[tileLocation]
                    let byte2 = tileData[tileLocation + 1]
                    
                    let spritePixelX = screenX - sprite.xPos
                    // Accept negative spritePixelX (off-screen left) and spritePixelX >= 8 (off-screen right)
                    if spritePixelX < 0 || spritePixelX >= 8 {
                        continue
                    }
                    let actualSpritePixelX = sprite.attributes.get(bit: 5) ? (7 - spritePixelX) : spritePixelX
                    let bitIndex = 7 - actualSpritePixelX
                    if bitIndex < 0 || bitIndex > 7 {
                        continue
                    }
                    let lsb = byte1.get(bit: UInt8(bitIndex))
                    let msb = byte2.get(bit: UInt8(bitIndex))
                    let colorIndex = (msb ? 2 : 0) + (lsb ? 1 : 0)
                    if colorIndex != 0 {
                        let palette1 = sprite.attributes.get(bit: 4)
                        objPixels[i] = colorIndex
                        objPriority[i] = sprite.attributes.get(bit: 7)
                        objPalette1[i] = palette1
                        break
                    }
                }
            }
            // If no non-transparent pixel found, leave as transparent (0)
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

    /// Write PPU mode (HBlank, VBlank, OAM, Draw)
    func write(mode: PPUMode) {
        self.mode = mode
    }
    
    /// Read current PPU mode
    public func readMode() -> PPUMode {
        return mode
    }
    
    /// Get the current display framebuffer (160x144 pixels)
    /// Returns the completed frame that should be displayed
    public func getDisplayBuffer() -> [Int] {
        return viewPort
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