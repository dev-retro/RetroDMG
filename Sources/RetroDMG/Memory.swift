//
//  Memory.swift
//
//
//  Created by Glenn Hevey on 24/12/2023.
//

import Foundation

struct Memory {
    var memory: [UInt8]
    var bootrom: [UInt8]
    var interruptEnabled: UInt8
    var interruptFlag: UInt8
    var bootromLoaded: Bool
    
    init() {
        memory = [UInt8](repeating: 0, count: 65537)
        bootrom = [UInt8](repeating: 0, count: 0x100)
        bootromLoaded = false
        interruptEnabled = 0x00
        interruptFlag = 0x00
    }
    
    mutating func write(location: UInt16, value: UInt8) {
        if location >= memory.endIndex {
            print("\(location.hex) is out of bounds")
            return
        }
        
        if location == 0xFF02 && value == 0x81 {
            print(memory[0xFF01])
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
        
        return memory[location]
    }
}
