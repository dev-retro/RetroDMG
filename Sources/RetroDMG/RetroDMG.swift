// The Swift Programming Language
// https://docs.swift.org/swift-book

public struct RetroDMG {
    var cpu: CPU
    
    public init() {
        self.cpu = CPU()
    }
    
    public mutating func tick() -> UInt16 {
        return cpu.tick()
    }
    
    public mutating func processInterrupt() {
        cpu.processInterrupt()
    }
    
    public mutating func updateTimer() {
        cpu.updateTimer()
    }
    
    public mutating func updateGraphics(cycles: UInt16) {
        cpu.bus.ppu.updateGraphics(cycles: cycles)
    }
    
    public mutating func debug(enabled: Bool) {
        cpu.debug = enabled
    }
    
    public func getState() -> String {
        cpu.currentState
    }
    
    public mutating func load(file: [UInt8]) {
        cpu.bus.write(rom: file)
        cpu.start()
    }
    
    public mutating func load(rom: [UInt8]) {
        cpu.bus.write(bootrom: rom)
        
    }
    
    public func shouldRender() -> Bool {
        cpu.bus.ppu.mode == .VerticalBlank
    }
    
    public func ppuTest() -> [Int] {
        return cpu.bus.ppu.createTile()
    }
    
    public func tileData() -> [Int] {
        return cpu.bus.ppu.createTileData()
    }
    
    public func tileMap() -> [Int] {
        return cpu.bus.ppu.createTileMap()
    }
    
    public mutating func viewPort() -> [Int] {
        return cpu.bus.ppu.viewPort
    }
}

extension UInt8 {
    var hex: String {
        String(format:"%02X", self)
    }
    
    init(_ boolean: Bool) {
         
        self = boolean ? 1 : 0
    }
}

extension UInt16 {
    var hex: String {
        String(format:"%04X", self)
    }
}
