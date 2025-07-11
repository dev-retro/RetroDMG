//
//  NoMBC.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 24/11/2024.
//

import Foundation

class NoMBC: MBCCart {
    /// NoMBC cartridges do not support RAM persistence.
    func getRAM() -> Data? {
        return nil
    }

    /// NoMBC cartridges do not support RAM persistence.
    func setRAM(_ data: Data) {
        // Do nothing
    }
    var data: [UInt8]
    
    required init(data: [UInt8]) {
        self.data = data
    }
    
    func read(location: UInt16) -> UInt8 {
        // Bounds check to prevent crashes
        if Int(location) >= data.count {
            return 0xFF
        }
        return data[Int(location)] 
    }

    func write(location: UInt16, value: UInt8) {
        // ROM area (0x0000-0x7FFF) is read-only
        if location >= 0x0000 && location <= 0x7FFF {
            return
        }
        
        // Bounds check to prevent memory corruption
        if Int(location) >= data.count {
            return
        }
        
        // Only allow writes to RAM areas (0xA000-0xBFFF for external RAM)
        if location >= 0xA000 && location <= 0xBFFF {
            data[Int(location)] = value
        }
    }
}
