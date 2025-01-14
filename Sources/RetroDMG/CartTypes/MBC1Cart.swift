//
//  MBC1Cart.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 23/11/2024.
//

import Foundation

class MBC1Cart: MBCCart {
    var data: [UInt8]
    var RAMSize: RAMSize
    var ROMSize: ROMSize
    var RAMG: Bool
    var bank1: UInt8
    var bank2: UInt8
    var mode: Bool

    required init(data: [UInt8]) {
        self.data = data
        self.RAMSize = .None
        self.ROMSize = ._32KB
        self.RAMG = false
        self.bank1 = 0x01
        self.bank2 = 0x00
        self.mode = false
    }
    
    init(data: [UInt8], RAMSize: RAMSize, ROMSize: ROMSize) {
        self.data = data
        self.RAMSize = RAMSize
        self.ROMSize = ROMSize
        self.RAMG = false
        self.bank1 = 0x01
        self.bank2 = 0x00
        self.mode = false
    }
    
    func read(location: UInt16) -> UInt8 {
        if location >= 0x0000 && location <= 0x3FFF {
            var location = Int(location)
            if mode == false {
                return data[location]
            }
            
            let offset = Int(UInt16(bank2) << 5 & (ROMSize.bankCount - 1)) << 14
            location = offset | location
            return data[location]
            
        }
        if location >= 0x4000 && location <= 0x7FFF {
            var location = Int(location & 0x3FFF)

            let offset = Int((UInt16(bank2) << 5 | UInt16(bank1)) & (ROMSize.bankCount - 1)) << 14
            location = offset | location
            return data[location]
        }
        if location >= 0xA000 && location <= 0xBFFF {
            var location = Int(location & 0x1FFF)
            if RAMSize == .None || RAMG == false {
                return 0x00
            }

            if mode == false {
                return data[location]
            }

            let offset = Int(UInt16(bank2) & UInt16(RAMSize.bankCount - 1)) << 13
            location = offset | location
            return data[location]
        }
        return 0xFF
    }
    
    func write(location: UInt16, value: UInt8) {
        if location >= 0x0000 && location <= 0x1FFF {
            RAMG = value & 0x0F == 0x0A
        }
        else if location >= 0x2000 && location <= 0x3FFF {
            var v = value & 0x1F
            if v == 0x00 {
                v = 0x01
            }
            bank1 = v
        }
        else if location >= 0x4000 && location <= 0x5FFF {
            bank2 = value & 0x03
        }
        else if location >= 0x6000 && location <= 0x7FFF {
            mode = value.get(bit: 0)
        }
        else if location >= 0xA000 && location <= 0xBFFF {
            if RAMSize == .None || RAMG == false {
                return
            }
            var location = Int(location & 0x1FFF)
            if mode == false {
                data[location] = value
            }

            let offset = Int(UInt16(bank2) & UInt16(RAMSize.bankCount - 1)) << 13
            location = offset | location

            data[location] = value
        }
    }
}
