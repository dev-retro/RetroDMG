import RetroKit
import Foundation

/// The main entry point for the Nintendo Game Boy emulator library.
///
/// `RetroDMG` provides all core emulation functionality. Consumers of the library should use this class to:
/// - Load ROMs
/// - Control emulation (start, pause, stop)
/// - Update input state
/// - Retrieve graphics and state data
/// - Manage save data
///
/// **Note:** Input, graphics, audio, and serial I/O should be implemented by the consumer. This library provides only the emulation core and exposes data for integration.
///
/// ### Example Usage
/// ```swift
/// let emulator = RetroDMG()
/// emulator.load(file: romBytes)
/// emulator.start()
/// let frame = emulator.viewPort()
/// emulator.update(inputs: myInputs)
/// emulator.pause()
/// ```
public class RetroDMG: RetroPlatform {
    /// The display name of the platform.
    public var name = "Nintendo Game Boy"
    /// A description of the platform.
    public var description = "The Game Boy is an 8-bit fourth generation handheld game console developed and manufactured by Nintendo."
    /// The release year of the platform.
    public var releaseDate = 1989
    /// The number of supported players.
    public var noOfPlayers = 1
    /// The internal platform name.
    public var platformName = "RetroDMG"
    /// A description of the emulator library.
    public var platformDescription = "Retro platform library for the Nintendo Game Boy"
    /// The current debug state, including registers and input.
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
    
    
    /// Returns the list of supported input controls for the Game Boy.
    ///
    /// - Returns: An array of `RetroInput` representing all available input buttons.
    public func listInputs() -> [RetroInput] {
        return inputs
    }
    
    /// Updates the input state for the emulator.
    ///
    /// - Parameter inputs: An array of `RetroInput` representing the current input state.
    public func update(inputs: [RetroInput]) {
        self.inputs = inputs
    }
    
    /// Updates emulator settings, such as BIOS configuration.
    ///
    /// - Parameter settings: A type conforming to `RetroSettings`.
    public func update(settings: some RetroSettings) {
        if let settings = settings as? DMGSettings {
            if let bios = settings.bioSetting.value {
                cpu.bus.write(bootrom: bios)
            }
        }
    }
    
    /// Starts the emulation loop.
    ///
    /// - Returns: `true` if the emulator was already running, `false` if it was started.
    public func start() -> Bool {
        debug(enabled: false)
        if !loopRunning {
            loopRunning = true
            loop()
            return false
        }
        return true
    }
    
    /// Pauses the emulation loop.
    ///
    /// - Returns: Always returns `false` (reserved for future use).
    public func pause() -> Bool {
        loopRunning = false
        return false
    }
    
    /// Stops the emulation and resets the emulator state.
    ///
    /// - Returns: Always returns `false` (reserved for future use).
    public func stop() -> Bool {
        runTask?.cancel()
        debugTask?.cancel()
        reset()
        return false
    }
    
    func loop() {
        let frameDuration = Duration.milliseconds(16.74)
        var nextFrameTime = SuspendingClock().now + frameDuration
        runTask = Task {
            while loopRunning {
                if Task.isCancelled {
                    loopRunning = false
                    break
                }
                checkInput()
                // Emulation logic
                var cyclesThisFrame = 0
                while cyclesThisFrame < 70224 {
                    if Task.isCancelled {
                        loopRunning = false
                        break
                    }
                    let currentCycles = cpu.tick()
                    cyclesThisFrame += Int(currentCycles)
                    for _ in 0...(currentCycles / 4) {
                        cpu.updateTimer()
                    }
                    cpu.bus.ppu.updateGraphics(cycles: currentCycles)
                    cpu.bus.apu.tick(cycles: currentCycles)
                    cpu.processInterrupt()
                }
                // Wait until the next frame time
                let now = SuspendingClock().now
                if now < nextFrameTime {
                    let sleepDuration = nextFrameTime - now
                    try? await Task.sleep(for: sleepDuration, tolerance: .zero)
                } else {
                    // If we're behind, skip sleep and catch up
                    nextFrameTime = now
                }
                nextFrameTime += frameDuration
            }
        }
        if cpu.debug {
            debugTask = Task {
                while loopRunning {
                    if Task.isCancelled {
                        loopRunning = false
                        break
                    }
                    updateState()
                    try? await Task.sleep(for: frameDuration, tolerance: .zero)
                }
            }
        }
    }

    func updateState() {
        let state = debugState as! DMGState
        
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
        
        state.PcLoc.value = cpu.bus.read(location: cpu.registers.read(register: .PC)).hex
        state.PcLoc1.value = cpu.bus.read(location: cpu.registers.read(register: .PC)+1).hex
        state.PcLoc2.value = cpu.bus.read(location: cpu.registers.read(register: .PC)+2).hex
        state.PcLoc3.value = cpu.bus.read(location: cpu.registers.read(register: .PC)+3).hex
        
        debugState = state
    }
    
    /// Lists available emulator settings as a string (reserved for future use).
    ///
    /// - Throws: May throw in future implementations.
    /// - Returns: An empty string (reserved).
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
        cpu.bus.ppu.debugEnabled = enabled
    }
    
    
    /// Loads a Game Boy ROM into the emulator.
    ///
    /// - Parameter file: The ROM data as an array of bytes.
    public func load(file: [UInt8]) {
        do {
            // Load into MBC (authoritative for ROM banking)
            try cpu.bus.mbc.load(rom: file)
            // Mirror ROM into Bus.memory for debug/inspection and any code paths that read from memory[] directly
            #if DEBUG
            let head = file.prefix(8).map { String(format: "0x%02x", $0) }.joined(separator: ", ")
            print("[RetroDMG.load] ROM bytes=\(file.count) head=[\(head)]")
            #endif
            cpu.start()
        } catch {
            print(error)
        }
    }
    
    /// Returns the current display framebuffer (160x144 pixels).
    ///
    /// - Returns: An array of pixel values representing the current frame.
    public func viewPort() -> [Int] {
        return cpu.bus.ppu.viewPort
    }
    
    /// Returns tile data for a given number of rows and columns.
    ///
    /// - Parameters:
    ///   - rowCount: Number of tile rows.
    ///   - columnCount: Number of tile columns.
    /// - Returns: An array of pixel values for the requested tile region.
    public func tileData(rowCount: Int, columnCount: Int) -> [Int] {
        let tilemap = cpu.bus.ppu.tileData
        var viewPort = [Int]()
        let totalTiles = rowCount * columnCount
        let totalBytes = totalTiles * 16
        for rowIndex in stride(from: 0, to: totalBytes, by: rowCount * 2 * 8) {
            for columnIndex in stride(from: rowIndex, to: rowIndex + 16, by: 2) {
                for byteIndex in stride(from: columnIndex, to: columnIndex + rowCount * 16, by: 16) {
                    viewPort.append(contentsOf:
                        cpu.bus.ppu.createRow(byte1: tilemap[byteIndex], byte2: tilemap[byteIndex + 1], isBackground: true, objectPallete1: nil)
                    )
                }
            }
        }
        return viewPort
    }
    
    /// Returns the full tilemap for the background or window.
    ///
    /// - Parameter get9800: If `true`, returns the 0x9800 tilemap; otherwise, returns the 0x9C00 tilemap.
    /// - Returns: An array of pixel values for the requested tilemap.
    public func tileMap(get9800: Bool) -> [Int] {
        let memory = cpu.bus.ppu.tileData
        let tilemap = get9800 ? cpu.bus.ppu.tilemap9800 : cpu.bus.ppu.tilemap9C00
        var tilemapBytes = [UInt8]()
        var viewPort = [Int]()
        for address in 0..<1024 {
            let tileNo = tilemap[address]
            let tileLocation = cpu.bus.ppu.read(flag: .TileDataSelect) ? Int(tileNo) * 16 : 0x1000 + Int(Int8(bitPattern: tileNo)) * 16
            tilemapBytes.append(contentsOf: memory[tileLocation..<tileLocation + 16])
        }
        let totalTiles = 32 * 32
        let totalBytes = totalTiles * 16
        for rowIndex in stride(from: 0, to: totalBytes, by: 32 * 2 * 8) {
            for columnIndex in stride(from: rowIndex, to: rowIndex + 16, by: 2) {
                for byteIndex in stride(from: columnIndex, to: columnIndex + 32 * 16, by: 16) {
                    viewPort.append(contentsOf:
                        cpu.bus.ppu.createRow(byte1: tilemapBytes[byteIndex], byte2: tilemapBytes[byteIndex + 1], isBackground: true, objectPallete1: nil)
                    )
                }
            }
        }
        return viewPort
    }

    // MARK: - Persistence API

    /// Loads battery-backed RAM data into the current cartridge (MBC), if supported.
    ///
    /// - Parameter data: The save data to load. If the cartridge does not support RAM, this is a no-op.
    public func loadSaveData(_ data: Data?) {
        guard let cart = cpu.bus.mbc.cart, let saveData = data else { return }
        cart.setRAM(saveData)
    }

    /// Retrieves battery-backed RAM data and identifying info from the current cartridge (MBC), if supported.
    ///
    /// - Returns: A dictionary containing `saveData`, `title`, `type`, and `hash` if available; otherwise, `nil`.
    public func getSaveDataWithInfo() -> [String: Any]? {
        guard let cart = cpu.bus.mbc.cart else { return nil }
        let saveData = cart.getRAM()
        return [
            "saveData": saveData as Any,
            "title": cart.cartridgeTitle,
            "type": cart.cartridgeType,
            "hash": cart.romHash
        ]
    }
    
    // MARK: - Test Harness Support
    
    /// Get current PC value for test harness (internal use)
    func getCurrentPC() -> UInt16 {
        return cpu.registers.read(register: .PC)
    }
    
    /// Read memory at specified location for test harness (internal use)
    func readMemory(at location: UInt16) -> UInt8 {
        return cpu.bus.read(location: location)
    }
    
}
