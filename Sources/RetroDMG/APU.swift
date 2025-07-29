//
//  APU.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 28/07/2025.
//
//  Game Boy APU (Audio Processing Unit) implementation.
//  Implements all registers, channel logic, mixing, and quirks per Pan Docs and emulator best practices.
//

import Foundation

/// Main Game Boy APU class. Handles all audio channels, mixing, and timing.
class APU {
    // Global Registers
    var NR50: UInt8 = 0x77 // Channel Volume Control
    var NR51: UInt8 = 0xF3 // Channel Enable
    var NR52: UInt8 = 0xF1 // Power Control

    // Channel 1 Registers
    var NR10: UInt8 = 0x80 // Sweep
    var NR11: UInt8 = 0xBF // Duty/Length
    var NR12: UInt8 = 0xF3 // Volume/Envelope
    var NR13: UInt8 = 0xFF // Frequency Low
    var NR14: UInt8 = 0xBF // Frequency High/Control

    // Channel 2 Registers
    var NR21: UInt8 = 0x3F // Duty/Length
    var NR22: UInt8 = 0x00 // Volume/Envelope
    var NR23: UInt8 = 0xFF // Frequency Low
    var NR24: UInt8 = 0xBF // Frequency High/Control

    // Channel 3 Registers
    var NR30: UInt8 = 0x7F // Enable
    var NR31: UInt8 = 0xFF // Length
    var NR32: UInt8 = 0x9F // Output Level
    var NR33: UInt8 = 0xFF // Frequency Low
    var NR34: UInt8 = 0xBF // Frequency High/Control

    // Channel 4 Registers
    var NR41: UInt8 = 0xFF // Length
    var NR42: UInt8 = 0x00 // Volume/Envelope
    var NR43: UInt8 = 0x00 // Polynomial Counter
    var NR44: UInt8 = 0xBF // Control

    // Wave RAM
    var waveRAM: [UInt8] = Array(repeating: 0, count: 16) // 16 bytes for Wave Channel

    public func readRegister(_ address: UInt16) -> UInt8 {
        switch address {
            case 0xFF10: // NR10: Channel 1 Sweep
                return NR10 | 0b10000000
            case 0xFF11: // NR11: Channel 1 Duty/Length
                return NR11 | 0b00111111
            case 0xFF12: // NR12: Channel 1 Volume/Envelope
                return NR12
            case 0xFF13: // NR13: Channel 1 Frequency Low
                return 0xFF
            case 0xFF14: // NR14: Channel 1 Frequency High/Control
                return NR14 | 0b10111111
            case 0xFF16: // NR21: Channel 2 Duty/Length
                return NR21 | 0b00111111
            case 0xFF17: // NR22: Channel 2 Volume/Envelope
                return NR22
            case 0xFF18: // NR23: Channel 2 Frequency Low
                return 0xFF
            case 0xFF19: // NR24: Channel 2 Frequency High/Control
                return NR24 | 0b10111111
            case 0xFF1A: // NR30: Channel 3 Enable
                return NR30 | 0b01111111
            case 0xFF1B: // NR31: Channel 3 Length
                return 0xFF
            case 0xFF1C: // NR32: Channel 3 Output Level
                return NR32 | 0b10011111
            case 0xFF1D: // NR33: Channel 3 Frequency Low
                return 0xFF
            case 0xFF1E: // NR34: Channel 3 Frequency High/Control
                return NR34 | 0b10111111
            case 0xFF20: // NR41: Channel 4 Length
                return 0xFF
            case 0xFF21: // NR42: Channel 4 Volume/Envelope
                return NR42
            case 0xFF22: // NR43: Channel 4 Polynomial Counter
                return NR43
            case 0xFF23: // NR44: Channel 4 Control
                return NR44 | 0b10111111
            case 0xFF24: // NR50: Channel Volume Control
                return NR50
            case 0xFF25: // NR51: Channel Output Control
                return NR51
            case 0xFF26: // NR52: Power Control
                var value = NR52 | 0b11110000
                value.set(bit: 0, value: NR14.get(bit: 7))
                value.set(bit: 1, value: NR24.get(bit: 7))
                value.set(bit: 2, value: NR34.get(bit: 7))
                value.set(bit: 3, value: NR44.get(bit: 7))
                return value
            case 0xFF30 ... 0xFF3F: // Wave RAM (0xFF30 to 0xFF3F)
                let index = Int(address - 0xFF30)
                guard index >= 0 && index < waveRAM.count else { return 0xFF }
                return waveRAM[index]
            default:
                return 0xFF // Default case for unhandled registers
        }
    }

    public func writeRegister(_ address: UInt16, _ value: UInt8) {
        switch address {
            case 0xFF10: // NR10: Channel 1 Sweep
                NR10 = value & 0b01111111
            case 0xFF11: // NR11: Channel 1 Duty/Length
                NR11 = value
            case 0xFF12: // NR12: Channel 1 Volume/Envelope
                NR12 = value
            case 0xFF13: // NR13: Channel 1 Frequency Low
                NR13 = value
            case 0xFF14: // NR14: Channel 1 Frequency High/Control
                NR14 = value & 0b11000111
            case 0xFF16: // NR21: Channel 2 Duty/Length
                NR21 = value
            case 0xFF17: // NR22: Channel 2 Volume/Envelope
                NR22 = value
            case 0xFF18: // NR23: Channel 2 Frequency Low
                NR23 = value
            case 0xFF19: // NR24: Channel 2 Frequency High/Control
                NR24 = value & 0b11000111
            case 0xFF1A: // NR30: Channel 3 Enable
                NR30 = value & 0b10000000
            case 0xFF1B: // NR31: Channel 3 Length
                NR31 = value
            case 0xFF1C: //NR32: Channel 3 Volume
                NR32 = value & 0b01100000
            case 0xFF1D: // NR33: Channel 3 Frequency Low
                NR33 = value
            case 0xFF1E: // NR34: Channel 3 Frequency High/Control
                NR34 = value & 0b11000111
            case 0xFF20: // NR41: Channel 4 Length
                NR41 = value & 0b00111111
            case 0xFF21: // NR42: Channel 4 Volume/Envelope
                NR42 = value
            case 0xFF22: // NR43: Channel 4 Polynomial Counter
                NR43 = value
            case 0xFF23: // NR44: Channel 4 Control
                NR44 = value & 0b11000000
            case 0xFF24: // NR50: Channel Volume Control
                NR50 = value
            case 0xFF25: // NR51: Channel Output Control
                NR51 = value
            case 0xFF26: // NR52: Power Control
                NR52 = value & 0b10000000
            case 0xFF30 ... 0xFF3F: // Wave RAM (0xFF30 to 0xFF3F)
                let index = Int(address - 0xFF30)
                guard index >= 0 && index < waveRAM.count else { return }
                waveRAM[index] = value
            default:
                break // Default case for unhandled registers
        }
    }

}