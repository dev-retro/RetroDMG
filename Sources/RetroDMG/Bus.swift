//
//  Memory.swift
//
//
//  Created by Glenn Hevey on 24/12/2023.
//

import Foundation

struct Bus {
    var memory: [UInt8]
    var bootrom: [UInt8]
    var interruptEnabled: UInt8
    var interruptFlag: UInt8
    var bootromLoaded: Bool
    public var ppu: PPU
    var div: UInt16
    var lastDivCycle: UInt16
    
    
    init() {
        memory = [UInt8](repeating: 0, count: 65537)
        bootrom = [UInt8](repeating: 0, count: 0x100)
        bootromLoaded = false
        interruptEnabled = 0x00
        interruptFlag = 0x00
        ppu = PPU()
        div = 0x0000
        lastDivCycle = 0x0000
    }
    
    mutating func updateDiv(cycles: UInt16) {
        var divOverflowCheck = lastDivCycle.addingReportingOverflow(256)
        if divOverflowCheck.overflow || divOverflowCheck.partialValue <= cycles {
            div = div.addingReportingOverflow(0x1).partialValue
            lastDivCycle = cycles
        }
    }
    
    mutating func write(location: UInt16, value: UInt8) {
        if location >= memory.endIndex {
            print("\(location.hex) is out of bounds")
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
        } else if location == 0xFF0F {
            interruptFlag = value
        } else if location == 0xFF04 {
            div = 0x0000
            lastDivCycle = 0x0000
        } else if location == 0xFF40 {
            ppu.control = value
        } else if location == 0xFF42 {
            ppu.scy = value
        } else if location == 0xFF43 {
            ppu.scx = value
        } else if location == 0xFF44 {
            return
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
    
    mutating func write(bootrom: [UInt8]) {
        self.bootrom = bootrom
        bootromLoaded = true
    }
    
    mutating func write(rom: [UInt8]) {
        memory.replaceSubrange(0...rom.count, with: rom)
    }
    
    mutating func write(interruptEnableType: InterruptType, value: Bool) {
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
    
    mutating func write(interruptFlagType: InterruptType, value: Bool) {
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
    
    mutating func read(location: UInt16) -> UInt8 {
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
            return ppu.tilemap9C00[Int(location - 0x9C00)]
        }
        
        if location == 0xFF00 {
            return 0xFF
        }
        
        if location == 0xFF0F {
            return interruptFlag
        }
        
        if location == 0xFF40 {
            return ppu.control
        }
        
        if location == 0xFF42 {
            return ppu.scx
        }
        
        if location == 0xFF43 {
            return ppu.scy
        }
        
        if location == 0xFF44 {
            return ppu.ly
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
}

enum InterruptType {
    case VBlank
    case LCD
    case Timer
    case Serial
    case Joypad
}


