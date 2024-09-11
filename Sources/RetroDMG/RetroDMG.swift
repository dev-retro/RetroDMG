// The Swift Programming Language
// https://docs.swift.org/swift-book

import RetroSwift
import Foundation

public class RetroDMG: RetroPlatform {
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
    
    public func update(inputs: [RetroInput]) {
        self.inputs = inputs
    }
    
    public func setup() -> Bool {
        //TODO: to add
        return false
    }
    
    public func start() -> Bool {
        loopRunning = true
        
        loop()
        return true
    }
    
    public func pause() -> Bool {
        //TODO: to add
        return false
    }
    
    public func stop() -> Bool {
        loopRunning = false
        return false
    }
    
    func loop() {
        Task {
            var time1 = SuspendingClock().now
            var time2 = SuspendingClock().now
            while loopRunning {
                time2 = SuspendingClock().now
                var elapsed = time2 - time1
                var reaminingTime = .milliseconds(16.67) - elapsed
                if reaminingTime > .milliseconds(1) {
                    await try? Task.sleep(for: reaminingTime, tolerance: .zero)
                }
                for _ in 0..<70224 / 16 { //Number is clock cycles per frame
                    let currentCycles = cpu.tick()
                    for _ in 0...(currentCycles / 4) {
                        cpu.updateTimer()
                    }
                    cpu.bus.ppu.updateGraphics(cycles: currentCycles)
                    cpu.processInterrupt()
                }
                time1 = time2
            }
        }
    }
    
    func checkInput() {
        for (index, input) in inputs.enumerated() {
            if input.updated {
                cpu.bus.write(inputType: InputType(rawValue: input.name)!, value: input.active)
                inputs[index].updated = false
                cpu.bus.write(interruptFlagType: .Joypad, value: true)
                cpu.bus.write(interruptEnableType: .Joypad, value: true)
            }
        }
    }
    
    public func tick() -> UInt16 {
        checkInput()
        return cpu.tick()
    }
    
    public func processInterrupt() {
        cpu.processInterrupt()
    }
    
    public func updateTimer() {
        cpu.updateTimer()
    }
    
    public func updateGraphics(cycles: UInt16) {
        cpu.bus.ppu.updateGraphics(cycles: cycles)
    }
    
    public func debug(enabled: Bool) {
        cpu.debug = enabled
    }
    
    public func getState() -> String {
        cpu.currentState
    }
    
    public func load(file: [UInt8]) {
        cpu.bus.write(rom: file)
        cpu.start()
    }
    
    public func load(rom: [UInt8]) {
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
    
    public func viewPort() -> [Int] {
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
