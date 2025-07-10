
//
//  Bus.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 24/12/2023.
//
//  Game Boy system bus and memory controller.
//  Handles all memory-mapped IO, RAM, VRAM, OAM, boot ROM, and cartridge access.
//  Implements hardware-accurate memory access rules for the PPU, MBC, DMA, timers, and input.
//
//  Key references:
//  - https://gbdev.io/pandocs/Memory_Map.html
//  - https://gbdev.io/pandocs/IO_Registers.html
//  - https://gbdev.io/pandocs/VRAM.html
//  - https://gbdev.io/pandocs/OAM.html
//  - https://gbdev.io/pandocs/Palettes.html
//

import Foundation

/// Main Game Boy system bus and memory controller.
/// Handles all memory-mapped IO, RAM, VRAM, OAM, boot ROM, and cartridge access.
/// Implements hardware-accurate memory access rules for the PPU, MBC, DMA, timers, and input.
class Bus {
    /// Main system RAM (including echo RAM)
    var memory: [UInt8]
    /// Boot ROM (0x0000-0x00FF)
    var bootrom: [UInt8]
    /// True if boot ROM is mapped
    var bootromLoaded: Bool
    /// Main PPU instance (handles all graphics)
    public var ppu: PPU
    /// Enable debug mode (bypasses normal memory rules)
    public var debug = false
    /// Main cartridge MBC (handles ROM/RAM banking)
    public var mbc: MBC

    // --- Interrupt registers ---
    /// Interrupt enable register (IE, 0xFFFF)
    var interruptEnabled: UInt8
    /// Interrupt flag register (IF, 0xFF0F)
    var interruptFlag: UInt8

    // --- Timer registers ---
    /// Divider register (DIV, 0xFF04)
    var div: UInt16
    /// Timer control (TAC, 0xFF07)
    var tac: UInt8
    /// Timer counter (TIMA, 0xFF05)
    var tima: UInt8
    /// Timer modulo (TMA, 0xFF06)
    var tma: UInt8

    // --- Input ---
    /// Joypad register (JOYP, 0xFF00)
    var joyp: UInt8
    /// Button state storage
    var buttonsStore: UInt8
    /// D-pad state storage
    var dpadStore: UInt8

    /// Initialize all memory, IO, and PPU state
    init() {
        memory = [UInt8](repeating: 0, count: 65537)
        bootrom = [UInt8](repeating: 0, count: 0x100)
        bootromLoaded = false
        interruptEnabled = 0x00
        interruptFlag = 0x00
        ppu = PPU()
        mbc = MBC()
        div = 0x0000
        tac = 0x00
        tima = 0x00
        tma = 0x00
        joyp = 0x3F
        buttonsStore = 0xFF
        dpadStore = 0xFF
    }
    
    /// Write a byte to the given memory location, handling all memory-mapped IO and hardware rules.
    /// - Parameters:
    ///   - location: The 16-bit address to write to
    ///   - value: The byte value to write
    func write(location: UInt16, value: UInt8) {
        if debug {
            return memory[Int(location)] = value
        }
        
        if location >= memory.endIndex {
            print("\(location.hex) is out of bounds")
            return
        }
        
        if location >= 0x0000 && location <= 0x7FFF {
            do {
                try mbc.write(location: location, value: value)
            } catch {
                print(error.localizedDescription)
            }
        }
        if location >= 0x8000 && location <= 0x97FF {
            ppu.tileData[Int(location - 0x8000)] = value
        } else if location >= 0x9800 && location <= 0x9BFF {
            if !ppu.read(flag: .Mode3) {
                ppu.tilemap9800[Int(location - 0x9800)] = value
            }
        } else if location >= 0x9C00 && location <= 0x9FFF {
            if !ppu.read(flag: .Mode3) {
                ppu.tilemap9C00[Int(location - 0x9C00)] = value
            }
        } else if location >= 0xA000 && location <= 0xBFFF {
            do {
                try mbc.write(location: location, value: value)
            } catch {
                print(error.localizedDescription)
            }
        } else if location >= 0xE000 && location <= 0xFDFF {
            memory[Int(location - 0x2000)] = value
        } else if location >= 0xFE00 && location <= 0xFE9F {
            if !ppu.read(flag: .Mode2) && !ppu.read(flag: .Mode3) {
                ppu.oam[Int(location - 0xFE00)] = value
            }
        } else if location == 0xFF00 {
            joyp = value
        } else if location == 0xFF04 {
            div = 0x0000
        } else if location == 0xFF05 {
            tima = value
        } else if location == 0xFF06 {
            tma = value
        } else if location == 0xFF07 {
            tac = value
        } else if location == 0xFF0F {
            interruptFlag = value & 0b00011111
        } else if location == 0xFF40 {
            ppu.control = value
        } else if location == 0xFF41 {
            // Only bits 3-6 are writable, per GBDEV
            let mask: UInt8 = 0b01111000
            ppu.status = (ppu.status & ~mask) | (value & mask)
        } else if location == 0xFF42 {
            ppu.scy = value
        } else if location == 0xFF43 {
            ppu.scx = value
        } else if location == 0xFF44 {
            return
        } else if location == 0xFF45 {
            ppu.lyc = value
        } else if location == 0xFF46 {
            ppu.dma = value
            let firstIndex = UInt16(value) << 8 | UInt16(0x00)
            let lastIndex = UInt16(value) << 8 | UInt16(0xFF)
            
            let data = memory[Int(firstIndex)...Int(lastIndex)]
            ppu.oam = Array(data)
        } else if location == 0xFF47 {
            ppu.bgp = value
        } else if location == 0xFF48 {
            let mask: UInt8 = 0b11111100
            ppu.obp0 = value & mask
        } else if location == 0xFF49 {
            let mask: UInt8 = 0b11111100
            ppu.obp1 = value & mask
        } else if location == 0xFF4A {
            ppu.wy = value
        } else if location == 0xFF4B {
            ppu.wx = value
        } else if location == 0xFFFF {
            interruptEnabled = value
        }
        //        else if location == 0xFF02 && value == 0x81 {
        //            print(Character(UnicodeScalar(memory[0xFF01])), terminator: "")
        //        }
        else {
            memory[Int(location)] = value
        }
    }
    
    /// Load the boot ROM into memory and enable boot ROM mapping.
    func write(bootrom: [UInt8]) {
        self.bootrom = bootrom
        bootromLoaded = true
    }
    
    /// Load the main cartridge ROM into memory.
    func write(rom: [UInt8]) {
        memory.replaceSubrange(0..<rom.count, with: rom)
    }
    
    /// Set or clear a specific interrupt flag in the IF register.
    func write(interruptFlagType: InterruptType, value: Bool) {
        switch interruptFlagType {
        case .VBlank:
            interruptFlag.set(bit: 0, value: value)
        case .LCD:
            interruptFlag.set(bit: 1, value: value)
        case .Timer:
            interruptFlag.set(bit: 2, value: value)
        case .Serial:
            interruptFlag.set(bit: 3, value: value)
        case .Joypad:
            interruptFlag.set(bit: 4, value: value)
        }
    }
    
    /// Set or clear a specific input bit in the joypad register.
    func write(inputType: InputType, value: Bool) {
        switch inputType {
        case .a:
            buttonsStore.set(bit: 0, value: !value)
        case .b:
            buttonsStore.set(bit: 1, value: !value)
        case .select:
            buttonsStore.set(bit: 2, value: !value)
        case .start:
            buttonsStore.set(bit: 3, value: !value)
        case .right:
            dpadStore.set(bit: 0, value: !value)
        case .left:
            dpadStore.set(bit: 1, value: !value)
        case .up:
            dpadStore.set(bit: 2, value: !value)
        case .down:
            dpadStore.set(bit: 3, value: !value)
        }
    }
        
        /// Read a byte from the given memory location, handling all memory-mapped IO and hardware rules.
        /// - Parameter location: The 16-bit address to read from
        /// - Returns: The byte value at the given address
        func read(location: UInt16) -> UInt8 {
            if debug {
                return memory[Int(location)]
            }
            
            let location = Int(location)
            if location > memory.count {
                return 0
            }
            
            if location < 0x100 && bootromLoaded {
                return bootrom[location]
            }
            
            if bootromLoaded && location == 0x100 {
                bootromLoaded = false
            }
            
            if location >= 0x0000 && location <= 0x7FFF {
                do {
                    return try mbc.read(location: UInt16(location))
                } catch {
                    print(error.localizedDescription)
                    return 0
                }
                
            }
            
            if location >= 0x8000 && location <= 0x97FF {
                if ppu.read(flag: .Mode3) {
                    return 0xFF
                }
                return ppu.tileData[Int(location - 0x8000)]
            }
            
            if location >= 0x9800 && location <= 0x9BFF {
                if ppu.read(flag: .Mode3) {
                    return 0xFF
                }
                return ppu.tilemap9800[Int(location - 0x9800)]
            }
            
            if location >= 0x9C00 && location <= 0x9FFF {
                if ppu.read(flag: .Mode3) {
                    return 0xFF
                }
                return ppu.tilemap9C00[Int(location - 0x9C00)]
            }
            if location >= 0xE000 && location <= 0xFDFF {
                return memory[Int(location - 0x2000)]
            }
            if location >= 0xFE00 && location <= 0xFE9F {
                if ppu.read(flag: .Mode2) || ppu.read(flag: .Mode3) {
                    return 0xFF
                }
                return ppu.oam[Int(location - 0xFE00)]
            }
            
            if location == 0xFF00 {
                let dpadCheck = !joyp.get(bit: 4)
                let buttonsCheck = !joyp.get(bit: 5)
                
                if dpadCheck {
                    let mask = UInt8(0b11000000)
                    let value = (joyp | dpadStore) | mask
                    
                    return value
                } else if buttonsCheck {
                    let mask = UInt8(0b11000000)
                    let value = (joyp | buttonsStore) | mask
                    
                    return value
                }
                
                return 0xFF
                
                
            }
            
            if location == 0xFF04 {
                let upper = UInt8(div >> 8)
                return upper
            }
            
            if location == 0xFF05 {
                return tima
            }
            
            if location == 0xFF06 {
                return tma
            }
            
            if location == 0xFF07 {
                return tac
            }
            
            if location == 0xFF0F {
                return interruptFlag
            }
            
            if location == 0xFF40 {
                return ppu.control
            }
            
            if location == 0xFF41 {
                return ppu.status
            }
            
            if location == 0xFF42 {
                return ppu.scy
            }
            
            if location == 0xFF43 {
                return ppu.scx
            }
            
            if location == 0xFF44 {
                return ppu.ly
            }
            
            if location == 0xFF45 {
                return ppu.lyc
            }
            
            if location == 0xFF46 {
                return ppu.dma
            }
            
            if location == 0xFF47 {
                return ppu.bgp
            }
            
            if location == 0xFF48 {
                return ppu.obp0
            }
            
            if location == 0xFF49 {
                return ppu.obp1
            }
            
            if location == 0xFF4A {
                return ppu.wy
            }
            
            if location == 0xFF4B {
                return ppu.wx
            }
            
            if location == 0xFF4D {
                return 0xFF //TODO: Implement speed switch for CGB
            }
            
            if location == 0xFFFF {
                return interruptEnabled
            }
            
            return memory[location]
        }
        
        /// Read a specific interrupt enable bit from the IE register.
        func read(interruptEnableType: InterruptType) -> Bool {
            switch interruptEnableType {
            case .VBlank:
                interruptEnabled.get(bit: 0)
            case .LCD:
                interruptEnabled.get(bit: 1)
            case .Timer:
                interruptEnabled.get(bit: 2)
            case .Serial:
                interruptEnabled.get(bit: 3)
            case .Joypad:
                interruptEnabled.get(bit: 4)
            }
        }
        
        /// Read a specific interrupt flag bit from the IF register.
        func read(interruptFlagType: InterruptType) -> Bool {
            switch interruptFlagType {
            case .VBlank:
                return interruptFlag.get(bit: 0)
            case .LCD:
                return interruptFlag.get(bit: 1)
            case .Timer:
                return interruptFlag.get(bit: 2)
            case .Serial:
                return interruptFlag.get(bit: 3)
            case .Joypad:
                return interruptFlag.get(bit: 4)
            }
        }
        
        /// Read a specific bit from the timer control register (TAC).
        func read(tacType: TacType) -> Bool {
            switch tacType {
            case .low:
                return tac.get(bit: 0)
            case .high:
                return tac.get(bit: 1)
            case .enable:
                return tac.get(bit: 2)
            }
        }
        
        /// Read a specific bit from the joypad register (JOYP).
        func read(inputBit: UInt8) -> Bool {
            return joyp.get(bit: inputBit)
        }
    }
    
    /// Interrupt types for the Game Boy interrupt system.
    enum InterruptType {
        case VBlank
        case LCD
        case Timer
        case Serial
        case Joypad
    }
    
    /// Timer control register (TAC) bit types.
    enum TacType {
        case enable
        case low
        case high
    }
    
    /// Input button types for the Game Boy joypad.
    enum InputType: String {
        case up = "Up"
        case down = "Down"
        case left = "Left"
        case right = "Right"
        case a = "A"
        case b = "B"
        case start = "Start"
        case select = "Select"
    }
