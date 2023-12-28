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
        cpu.memory.write(rom: file)
    }
}

extension UInt8 {
    var hex: String {
        String(format:"%02X", self)
    }
}

extension UInt16 {
    var hex: String {
        String(format:"%04X", self)
    }
}
