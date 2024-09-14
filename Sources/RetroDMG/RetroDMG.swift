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
    var settings: DMGSettings
    
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
        self.settings = DMGSettings()
    }
    
    public func listInputs() -> [RetroInput] {
        return inputs
    }
    
    public func update(inputs: [RetroInput]) {
        self.inputs = inputs
    }
    
    public func setup(settings: String) throws -> Bool {
        let decoder = JSONDecoder()
        
        let settings = try decoder.decode(DMGSettings.self, from: settings.data(using: .utf8)!)
        
        if let bios = settings.bios {
            cpu.bus.write(bootrom: bios)
        }
        
        return true
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
                checkInput()
                time2 = SuspendingClock().now
                var elapsed = time2 - time1
                var reaminingTime = .milliseconds(16.67) - elapsed
                if reaminingTime > .milliseconds(1) {
                    await try? Task.sleep(for: reaminingTime, tolerance: .zero)
                }
                for _ in 0..<70224 / 16 {
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
    
    public func listSettings() throws -> String {
        let encoder = JSONEncoder()
        
        let settings = try encoder.encode(settings)
        
        return String(data: settings, encoding: .utf8)!
        
    }
    
    func checkInput() {
        for (index, input) in inputs.enumerated() {
            if input.updated {
                cpu.bus.write(inputType: InputType(rawValue: input.name)!, value: input.active)
                cpu.setInputInterrupt = true
                inputs[index].updated = false
            }
        }
    }
    
    func debug(enabled: Bool) {
        cpu.debug = enabled
    }
    
    
    public func load(file: [UInt8]) {
        cpu.bus.write(rom: file)
        cpu.start()
    }
    
//    func ppuTest() -> [Int] {
//        return cpu.bus.ppu.createTile()
//    }
//    
//    func tileData() -> [Int] {
//        return cpu.bus.ppu.createTileData()
//    }
//    
//    func tileMap() -> [Int] {
//        return cpu.bus.ppu.createTileMap()
//    }
    
    public func viewPort() -> [Int] {
        return cpu.bus.ppu.viewPort
    }
}
