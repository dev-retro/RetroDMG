//
//  Memory.swift
//
//
//  Created by Glenn Hevey on 24/12/2023.
//

import Foundation

class Bus {
    var memory: [UInt8]
    var bootrom: [UInt8]
    var bootromLoaded: Bool
    public var ppu: PPU
    
    ///Interrupt registers
    var interruptEnabled: UInt8
    var interruptFlag: UInt8
    
    /// Timer registers
    var div: UInt16
    var tac: UInt8
    var tima: UInt8
    var tma: UInt8
    
    /// Input
    var joyp: UInt8
    var buttonsStore: UInt8
    var dpadStore: UInt8
    
    var debug = false
    
    init() {
        memory = [UInt8](repeating: 0, count: 65537)
        bootrom = [UInt8](repeating: 0, count: 0x100)
        bootromLoaded = false
        interruptEnabled = 0x00
        interruptFlag = 0x00
        ppu = PPU()
        div = 0x0000
        tac = 0x00
        tima = 0x00
        tma = 0x00
        joyp = 0x3F
        buttonsStore = 0xFF
        dpadStore = 0xFF
    }
    
    func write(location: UInt16, value: UInt8) {
        if location >= memory.endIndex {
            print("\(location.hex) is out of bounds")
            return
        }
        
        if location >= 0x0000 && location <= 0x3FFF {
            return
        }
        if location >= 0x8000 && location <= 0x97FF {
            ppu.memory[Int(location - 0x8000)] = value
        } else if location >= 0x9800 && location <= 0x9BFF {
            if ppu.mode != .Draw {
                ppu.tilemap9800[Int(location - 0x9800)] = value
            }
        } else if location >= 0x9C00 && location <= 0x9FFF {
            if ppu.mode != .Draw {
                ppu.tilemap9C00[Int(location - 0x9C00)] = value
            }
        } else if location >= 0xFE00 && location <= 0xFE9F {
            if ppu.mode != .OAM && ppu.mode != .Draw {
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
            interruptFlag = value
        } else if location == 0xFF40 {
            ppu.control = value
        } else if location == 0xFF41 {
            ppu.status = value //FIXME: block writes to bit 0, 1 ans 2 see: https://gbdev.io/pandocs/STAT.html
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
            var lastIndex = UInt16(value) << 8 | UInt16(0xFF)
            
            var data = memory[Int(firstIndex)...Int(lastIndex)]
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
    
    func write(bootrom: [UInt8]) {
        self.bootrom = bootrom
        bootromLoaded = true
    }
    
    func write(rom: [UInt8]) {
        memory.replaceSubrange(0...rom.count, with: rom)
    }
    
    func write(interruptEnableType: InterruptType, value: Bool) {
        switch interruptEnableType {
         case .VBlank:
            interruptEnabled.set(bit: 0, value: value)
         case .LCD:
            interruptEnabled.set(bit: 1, value: value)
         case .Timer:
            interruptEnabled.set(bit: 2, value: value)
         case .Serial:
            interruptEnabled.set(bit: 3, value: value)
         case .Joypad:
            interruptEnabled.set(bit: 4, value: value)
        default:
            fatalError("Interrupt Type not implemented \(interruptEnableType)")
        }
    }
    
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
        default:
            fatalError("Interrupt Type not implemented \(interruptFlagType)")
        }
    }
    
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
            default:
                fatalError("Input Type not implemented \(inputType)")
            }
    }
    
    func read(location: UInt16) -> UInt8 {
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
        
        if location >= 0x8000 && location <= 0x97FF {
            if ppu.mode == .Draw {
                return 0xFF
            }
            return ppu.memory[Int(location - 0x8000)]
        }
        
        if location >= 0x9800 && location <= 0x9BFF {
            if ppu.mode == .Draw {
                return 0xFF
            }
            return ppu.tilemap9800[Int(location - 0x9800)]
        }
        
        if location >= 0x9C00 && location <= 0x9FFF {
            if ppu.mode == .Draw {
                return 0xFF
            }
            return ppu.tilemap9C00[Int(location - 0x9C00)]
        }
        
        if location >= 0xFE00 && location <= 0xFE9F {
            if ppu.mode == .OAM || ppu.mode == .Draw {
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
            var upper = UInt8(div >> 8)
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
        
        if location == 0xFFFF {
            return interruptEnabled
        }
        
        return memory[location]
    }
    
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
        default:
            fatalError("Interrupt Type not implemented \(interruptEnableType)")
        }
    }
    
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
        default:
            fatalError("Interrupt Type not implemented \(interruptFlagType)")
        }
    }
    
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
    
    func read(inputBit: UInt8) -> Bool {
        return joyp.get(bit: inputBit)
    }
}

enum InterruptType {
    case VBlank
    case LCD
    case Timer
    case Serial
    case Joypad
}

enum TacType {
    case enable
    case low
    case high
}

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
