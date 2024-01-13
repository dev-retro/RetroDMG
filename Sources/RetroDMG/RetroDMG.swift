// The Swift Programming Language
// https://docs.swift.org/swift-book

public struct RetroDMG {
    var cpu: CPU
    
    public init() {
        self.cpu = CPU()
    }
    
    public mutating func tick() {
        cpu.tick()
    }
    
    public mutating func load(file: [UInt8]) {
        cpu.bus.write(rom: file)
        cpu.start()
    }
    
    public mutating func load(rom: [UInt8]) {
        cpu.bus.write(bootrom: rom)
        cpu.bus.bootromLoaded = true
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
        cpu.bus.ppu.fetch()
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
