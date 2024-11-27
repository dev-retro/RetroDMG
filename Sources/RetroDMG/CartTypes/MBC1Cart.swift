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
    var mode: UInt8
    
    required init(data: [UInt8]) {
        self.data = data
        self.RAMSize = 0
        self.RAMG = false
        self.bank1 = 0
        self.bank2 = 0
        self.mode = 0
    }
    
    init(data: [UInt8], RAMSize: UInt8) {
        self.data = data
        self.RAMSize = RAMSize
        self.RAMG = false
        self.bank1 = 0
        self.bank2 = 0
        self.mode = 0
    }
    
    func read(location: UInt16) -> UInt8 {
        if location >= 0x0000 && location <= 0x3FFF {
            if mode != 0x01 {
                return data[Int(location)]
            } else  {
                return data[Int(UInt16(bank2) << 5 | location)]
            }
        }
        if location >= 0x4000 && location <= 0x7FFF {
            let offset = UInt16(bank2) << 5 | UInt16(bank1)
            return data[Int(offset << 14) | Int(location)]
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
            bank1 = bank1 == 0 ? 1 : bank1
            bank2 = value & 0x30 >> 4
        }
        else if location >= 0x6000 && location <= 0x7FFF {
            mode = value & 0x01
        }
        else if location >= 0xA000 && location <= 0xBFFF && RAMG {
            data[Int(location)] = value
        }
    }
}
