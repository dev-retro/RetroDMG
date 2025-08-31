//
//  File.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 30/8/2025.
//

import Foundation

class APU {
    /// Channel 1 (Sweep + Square)
    var NR10: UInt8
    var NR11: UInt8
    var NR12: UInt8
    var NR13: UInt8
    var NR14: UInt8
    
    /// Channel 2 (Square)
    var NR21: UInt8
    var NR22: UInt8
    var NR23: UInt8
    var NR24: UInt8
    
    /// Channel 3 (Wave)
    var NR30: UInt8
    var NR31: UInt8
    var NR32: UInt8
    var NR33: UInt8
    var NR34: UInt8
    
    /// Channel 4 (Noise)
    var NR41: UInt8
    var NR42: UInt8
    var NR43: UInt8
    var NR44: UInt8
    
    /// Global
    var NR50: UInt8
    var NR51: UInt8
    var NR52: UInt8
    
    /// Wave RAM
    var waveRAM: [UInt8]
    
    init() {
        /// Channel 1
        NR10 = 0x80
        NR11 = 0xBF
        NR12 = 0xF3
        NR13 = 0xFF
        NR14 = 0xBF
        
        /// Channel 2
        NR21 = 0x3F
        NR22 = 0x00
        NR23 = 0xFF
        NR24 = 0xBF
        
        /// Channel 3
        NR30 = 0x7F
        NR31 = 0xFF
        NR32 = 0x9F
        NR33 = 0xFF
        NR34 = 0xBF
        
        /// Channel 4
        NR41 = 0xFF
        NR42 = 0x00
        NR43 = 0x00
        NR44 = 0xBF
        
        /// Global
        NR50 = 0x77
        NR51 = 0xF3
        NR52 = 0xF1
        
        /// Wave RAM
        waveRAM = [UInt8](repeating: 0x00, count: 16)
    }
    
    func read(register: UInt16) -> UInt8 {
        var value: UInt8 = 0xFF
        
        switch register {
        /// Channel 1
        case 0xFF10:
            value = NR10 | 0b10000000
        case 0xFF11:
            value = (NR11 & 0b11000000) | 0b00111111
        case 0xFF12:
            value = NR12
        case 0xFF13:
            value = 0b11111111
        case 0xFF14:
            value = (NR14 & 0b01000000) | 0b10111111
        /// Channel 2
        case 0xFF16:
            value = (NR21 & 0b11000000) | 0b00111111
        case 0xFF17:
            value = NR22
        case 0xFF18:
            value = 0b11111111
        case 0xFF19:
            value = (NR24 & 0b01000000) | 0b10111111
        /// Channel 3
        case 0xFF1A:
            value = (NR30 & 0b10000000) | 0b01111111
        case 0xFF1B:
            value = 0b11111111
        case 0xFF1C:
            value = (NR32 & 0b01100000) | 0b10011111
        case 0xFF1D:
            value = 0b11111111
        case 0xFF1E:
            value = (NR34 & 0b01000000) | 0b10111111
        /// Channel 4
        case 0xFF20:
            value = 0b11111111
        case 0xFF21:
            value = NR42
        case 0xFF22:
            value = NR43
        case 0xFF23:
            value = (NR44 & 0b01000000) | 0b10111111
        /// Global
        case 0xFF24:
            value = NR50
        case 0xFF25:
            value = NR51
        case 0xFF26:
            value = (NR52 & 0b10001111) | 0b01110000
        /// Wave RAM
        case 0xFF30...0xFF3F:
            value = waveRAM[Int(register - 0xFF30)]
        /// Default
        default:
            value = 0xFF
        }
        
        return value
    }
    
    func write(register: UInt16, value: UInt8) {
        if !NR52.get(bit: 7) {
            if register == 0xFF26 {
                NR52.set(bit: 7, value: value.get(bit: 7))
                return
            }
            
            if register >= 0xFF30 && register <= 0xFF3F {
                waveRAM[Int(register - 0xFF30)] = value
                return
            }
            
            return
        }
        switch register {
        /// Channel 1
        case 0xFF10:
            NR10 = value & 0b01111111
        case 0xFF11:
            NR11 = value
        case 0xFF12:
            NR12 = value
        case 0xFF13:
            NR13 = value
        case 0xFF14:
            NR14 = value & 0b11000111
        /// Channel 2
        case 0xFF16:
            NR21 = value
        case 0xFF17:
            NR22 = value
        case 0xFF18:
            NR23 = value
        case 0xFF19:
            NR24 = value & 0b11000111
        /// Channel 3
        case 0xFF1A:
            NR30 = value & 0b10000000
        case 0xFF1B:
            NR31 = value
        case 0xFF1C:
            NR32 = value & 0b01100000
        case 0xFF1D:
            NR33 = value
        case 0xFF1E:
            NR34 = value & 0b11000111
        /// Channel 4
        case 0xFF20:
            NR41 = value & 0b00111111
        case 0xFF21:
            NR42 = value
        case 0xFF22:
            NR43 = value
        case 0xFF23:
            NR44 = value & 0b11000000
        /// Global
        case 0xFF24:
            NR50 = value
        case 0xFF25:
            NR51 = value
        case 0xFF26:
            if (NR51.get(bit: 7) && !value.get(bit: 7)) {
                powerOff()
            }
            NR52 = value & 0b10000000
        /// Wave RAM
        case 0xFF30...0xFF3F:
            waveRAM[Int(register - 0xFF30)] = value
        /// Default
        default:
            break
        }
    }
    
    func powerOff() {
        /// Channel 1
        NR10 = 0x00
        NR11 = 0x00
        NR12 = 0x00
        NR13 = 0x00
        NR14 = 0x00
        /// Channel 2
        NR21 = 0x00
        NR22 = 0x00
        NR23 = 0x00
        NR24 = 0x00
        /// Channel 3
        NR30 = 0x00
        NR31 = 0x00
        NR32 = 0x00
        NR33 = 0x00
        NR34 = 0x00
        /// Channel 4
        NR41 = 0x00
        NR42 = 0x00
        NR43 = 0x00
        NR44 = 0x00
        /// Global
        NR50 = 0x00
        NR51 = 0x00
        NR52 = 0x00
    }
    
    func tick(cycles: UInt16) {
        
    }
}
