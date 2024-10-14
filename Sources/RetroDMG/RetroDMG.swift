import RetroSwift
import Foundation

public class RetroDMG: RetroPlatform {
    public var name = "Nintendo Game Boy"
    public var description = "The Game Boy is an 8-bit fourth generation handheld game console developed and manufactured by Nintendo."
    public var releaseDate = 1989
    public var noOfPlayers = 1
    public var platformName = "RetroDMG"
    public var platformDescription = "Retro platform library for the Nintendo Game Boy"
    public var debugState: any RetroState
    
    var cpu: CPU
    var inputs: [RetroInput]
    var loopRunning: Bool
    
    var runTask: Task<(), Never>?
    var debugTask: Task<(), Never>?
    
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
        
        self.debugState = DMGState()
        
        self.loopRunning = false
    }
    
    func reset() {
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
        
        self.debugState = DMGState()
        
        self.loopRunning = false
    }
    
    
    public func listInputs() -> [RetroInput] {
        return inputs
    }
    
    public func update(inputs: [RetroInput]) {
        self.inputs = inputs
    }
    
    public func update(settings: some RetroSettings) {
        if let settings = settings as? DMGSettings {
            if let bios = settings.bioSetting.value {
                cpu.bus.write(bootrom: bios)
            }
        }
    }
    
    public func start() -> Bool {
        
        if !loopRunning {
            loopRunning = true
            
            loop()
            return false
        }
        
        return true
    }
    
    public func pause() -> Bool {
        loopRunning = false
        return false
    }
    
    public func stop() -> Bool {
        runTask?.cancel()
        debugTask?.cancel()
        reset()
        return false
    }
    
    func loop() {
        var time1 = SuspendingClock().now
        var time2 = SuspendingClock().now
        runTask = Task {
            while loopRunning {
                if Task.isCancelled {
                    loopRunning = false
                    break
                }
                checkInput()
                time2 = SuspendingClock().now
                var elapsed = time2 - time1
                var reaminingTime = .milliseconds(16.67) - elapsed
                if reaminingTime > .milliseconds(1) {
                    await try? Task.sleep(for: reaminingTime, tolerance: .zero)
                }
                for _ in 0..<70224 / 16 {
//                    if Task.isCancelled {
//                        loopRunning = false
//                        break
//                    }
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
        debugTask = Task {
            while loopRunning {
                if Task.isCancelled {
                    loopRunning = false
                    break
                }
                var elapsed = time2 - time1
                var reaminingTime = .milliseconds(16.67) - elapsed
                if reaminingTime > .milliseconds(1) {
                    await try? Task.sleep(for: reaminingTime, tolerance: .zero)
                }
                updateState()
            }
        }
    }
    
    func updateState() {
        var state = debugState as! DMGState
        
        state.a.value = cpu.registers.a
        state.b.value = cpu.registers.b
        state.c.value = cpu.registers.c
        state.d.value = cpu.registers.d
        state.e.value = cpu.registers.e
        state.f.value = cpu.registers.f
        state.h.value = cpu.registers.h
        state.l.value = cpu.registers.l
        state.pc.value = cpu.registers.pc
        state.sp.value = cpu.registers.sp
        state.ime.value = cpu.registers.ime
        
        state.JoyP.value = cpu.bus.read(location: 0xFF00)
        state.InputA.value = !cpu.bus.buttonsStore.get(bit: 0)
        state.InputB.value = !cpu.bus.buttonsStore.get(bit: 1)
        state.InputSelect.value = !cpu.bus.buttonsStore.get(bit: 2)
        state.InputStart.value = !cpu.bus.buttonsStore.get(bit: 3)
        state.InputRight.value = !cpu.bus.dpadStore.get(bit: 0)
        state.InputLeft.value = !cpu.bus.dpadStore.get(bit: 1)
        state.InputUp.value = !cpu.bus.dpadStore.get(bit: 2)
        state.InputDown.value = !cpu.bus.dpadStore.get(bit: 3)
        state.InputDPad.value = !cpu.bus.read(inputBit: 4)
        state.InputButtons.value = !cpu.bus.read(inputBit: 5)
        
        debugState = state
    }
    
    public func listSettings() throws -> String {
        return ""
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
    
    public func viewPort() -> [Int] {
        return cpu.bus.ppu.viewPort
    }
}
