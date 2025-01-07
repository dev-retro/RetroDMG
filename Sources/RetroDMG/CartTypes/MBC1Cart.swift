//
//  MBC1Cart.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 23/11/2024.
//

import Foundation

class MBC1Cart: MBCCart {
    var data: [UInt8]
    var RAMSize: UInt8
    var RAMG: Bool
    var bank1: UInt8
    var bank2: UInt8
    var mode: Bool
    var size: UInt8
    
    required init(data: [UInt8]) {
        self.data = data
        self.RAMSize = 0
        self.RAMG = false
        self.bank1 = 0
        self.bank2 = 0
        self.mode = false
        self.size = UInt8(data.count / 0x4000)
    }
    
    init(data: [UInt8], RAMSize: UInt8) {
        self.data = data
        self.RAMSize = RAMSize
        self.RAMG = false
        self.bank1 = 0
        self.bank2 = 0
        self.mode = false
        self.size = UInt8(data.count / 0x4000)
    }
    
    func read(location: UInt16) -> UInt8 {
        if location >= 0x0000 && location <= 0x3FFF {
            if mode == false {
                return data[Int(location & 0x3FFF)]
            } else  {
                var offset = UInt16(bank2) << 5 | UInt16(0x0000)
                offset = offset & UInt16(size)
                
                var locCombined = Int(offset) << 14 | Int(location)
                return data[locCombined]
            }
        }
        if location >= 0x4000 && location <= 0x7FFF {
            var offset = UInt16(bank2) << 5 | UInt16(bank1)
            offset = offset & UInt16(size)
            
            
            var locCombined = Int(offset) << 14 | Int(location)
            
            return data[locCombined]
        }
        if location >= 0xA000 && location <= 0xBFFF {
            return RAMG ? data[Int(location)] : 0x00
        }
        return data[Int(location)]
    }
    
    func write(location: UInt16, value: UInt8) {
        if location >= 0x0000 && location <= 0x1FFF {
            RAMG = value & 0x0F == 0x0A
        }
        else if location >= 0x2000 && location <= 0x3FFF {
            bank1 = value & 0x1F
            bank1 = bank1 == 0x00 ? 0x01 : bank1
        }
        else if location >= 0x4000 && location <= 0x5FFF {
            bank2 = value & 0x03
        }
        else if location >= 0x6000 && location <= 0x7FFF {
            mode = value.get(bit: 0)
        }
        else if location >= 0xA000 && location <= 0xBFFF && RAMG {
            data[Int(location)] = value
        }
    }
}
