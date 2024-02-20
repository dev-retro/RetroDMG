// The Swift Programming Language
// https://docs.swift.org/swift-book

import RetroSwift
import Foundation

public struct RetroDMG: RetroPlatform {
    public var name = "Nintendo Game Boy"
    public var description = "The Game Boy is an 8-bit fourth generation handheld game console developed and manufactured by Nintendo."
    public var releaseDate = 1989
    public var noOfPlayers = 1
    public var platformName = "RetroDMG"
    public var platformDescription = "Retro platform library for the Nintendo Game Boy"
    
    var cpu: CPU
    var inputs: [RetroInput]
    var loopRunning: Bool
    
    public init() {
        self.cpu = CPU()
        self.inputs = [
            RetroInput("Up"),
            RetroInput("Down"),
            RetroInput("Left"),
            RetroInput("Right"),
            RetroInput("A"),
            RetroInput("B"),
            RetroInput("Start"),
            RetroInput("Select")
        ]
        
        self.loopRunning = false
    }
    
    public func listInputs() -> [RetroInput] {
        return inputs
    }
    
    public mutating func update(inputs: [RetroInput]) {
        self.inputs = inputs
    }
    
    public mutating func setup() -> Bool {
        //TODO: to add
        return false
    }
    
    public mutating func start() -> Bool {
        //TODO: to add
        return false
    }
    
    public mutating func pause() -> Bool {
        //TODO: to add
        return false
    }
    
    public mutating func stop() -> Bool {
        //TODO: to add
        return false
    }
    
    mutating func loop() async {
        while true {
            //Input
            cpu.tick()
        }
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
