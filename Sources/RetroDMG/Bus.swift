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
    
    init() {
        memory = [UInt8](repeating: 0, count: 65537)
        bootrom = [UInt8](repeating: 0, count: 0x100)
        bootromLoaded = false
        interruptEnabled = 0x00
        interruptFlag = 0x00
        ppu = PPU()
    }
    
    mutating func write(location: UInt16, value: UInt8) {
        if location >= memory.endIndex {
            print("\(location.hex) is out of bounds")
            return
        }
        
        if location >= 0x8000 && location <= 0x97FF {
            ppu.memory[Int(location - 0x8000)] = value
        } else if location >= 0x9800 && location <= 0x9BFF {
            ppu.tileMapOne[Int(location - 0x9800)] = value
        } else if location >= 0x9C00 && location <= 0x9FFF {
            ppu.tileMapTwo[Int(location - 0x9C00)] = value
        }
        else if location == 0xFF02 && value == 0x81 {
            print(Character(UnicodeScalar(memory[0xFF01])), terminator: "")
        } else {
            memory[Int(location)] = value
        }
    }
    
    mutating func write(bootrom: [UInt8]) {
        self.bootrom = bootrom
    }
    
    mutating func write(rom: [UInt8]) {
        memory.replaceSubrange(0...rom.count, with: rom)
    }
    
    func read(location: UInt16) -> UInt8 {
        let location = Int(location)
        if location > memory.count {
            return 0
        }
        
        if location < 0x100 && bootromLoaded {
           return bootrom[location]
        }
        
        if location >= 0x8000 && location <= 0x97FF {
            return ppu.memory[Int(location - 0x8000)]
        }
        
        if location >= 0x9800 && location <= 0x9BFF {
            return ppu.tileMapOne[Int(location - 0x9800)]
        }
        
        if location >= 0x9C00 && location <= 0x9FFF {
            ppu.tileMapTwo[Int(location - 0x9C00)]
        }
        
        if location == 0xFF44 {
            return 0x90 //FIXME: stubbed for now. Remove when required
        }
        
        return memory[location]
    }
}
