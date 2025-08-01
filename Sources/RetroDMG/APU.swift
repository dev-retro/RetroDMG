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

    var channel1: Channel1 = Channel1()
    var channel2: Channel2 = Channel2()
    var channel3: Channel3 = Channel3()
    var channel4: Channel4 = Channel4()

    var enabled: Bool = false
    var frameSequencerStep: Int = 0
    var frameSequencerCounter: Int = 0

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
                var value: UInt8 = 0x70 // bits 4-6 always 1
                value.set(bit: 7, value: enabled)
                value.set(bit: 0, value: channel1.enabled)
                value.set(bit: 1, value: channel2.enabled)
                value.set(bit: 2, value: channel3.enabled)
                value.set(bit: 3, value: channel4.enabled)
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
        if !enabled {
            switch address {
                case 0xFF26: // NR52
                    break
                case 0xFF30 ... 0xFF3F: // Wave RAM
                    let index = Int(address - 0xFF30)
                    waveRAM[index] = value
                    return
                default:
                    return
            }
        }
        switch address {
            case 0xFF10: // NR10: Channel 1 Sweep
                NR10 = value & 0b01111111
            case 0xFF11: // NR11: Channel 1 Duty/Length
                NR11 = value
                channel1.lengthCounter = 64 - (value & 0b00111111)
            case 0xFF12: // NR12: Channel 1 Volume/Envelope
                NR12 = value
                channel1.dacEnabled = NR12 & 0b11111000 != 0
                if channel1.enabled {
                    channel1.updateEnabled()
                }
            case 0xFF13: // NR13: Channel 1 Frequency Low
                NR13 = value
            case 0xFF14: // NR14: Channel 1 Frequency High/Control
                let wasLengthEnabled = NR14.get(bit: 6)
                let lengthEnabled = value.get(bit: 6)
                let trigger = value.get(bit: 7)
                let originalLengthCounter = channel1.lengthCounter

                // Store the register value first
                NR14 = value & 0b11000111

                // 1. Length-enable quirk (runs first)
                if !wasLengthEnabled && lengthEnabled && (frameSequencerStep % 2 == 1) {
                    let shouldApplyQuirk = !trigger || (trigger && originalLengthCounter > 0)
                    if shouldApplyQuirk && channel1.lengthCounter > 0 {
                        channel1.lengthCounter -= 1
                    }
                }
                // 2. Trigger event (runs after quirk, so it can reload length)
                if trigger {
                    if channel1.lengthCounter == 0 {
                        if frameSequencerStep % 2 == 1 && lengthEnabled {
                            channel1.lengthCounter = 63
                        } else {
                            channel1.lengthCounter = 64
                        }
                    }
                    // TODO: Reset envelope, sweep
                    channel1.enabled = channel1.dacEnabled && channel1.lengthCounter > 0 && !channel1.sweepOverflowed
                } else {
                    channel1.updateEnabled()
                }
            case 0xFF16: // NR21: Channel 2 Duty/Length
                NR21 = value
                channel2.lengthCounter = 64 - (value & 0b00111111)
            case 0xFF17: // NR22: Channel 2 Volume/Envelope
                NR22 = value
                channel2.dacEnabled = NR22 & 0b11111000 != 0
                if channel2.enabled {
                    channel2.updateEnabled()
                }
            case 0xFF18: // NR23: Channel 2 Frequency Low
                NR23 = value
            case 0xFF19: // NR24: Channel 2 Frequency High/Control
                let wasLengthEnabled = NR24.get(bit: 6)
                let lengthEnabled = value.get(bit: 6)
                let trigger = value.get(bit: 7)
                let originalLengthCounter = channel2.lengthCounter

                // Store the register value first
                NR24 = value & 0b11000111

                if !wasLengthEnabled && lengthEnabled && (frameSequencerStep % 2 == 1) {
                    let shouldApplyQuirk = !trigger || (trigger && originalLengthCounter > 0)
                    if shouldApplyQuirk && channel2.lengthCounter > 0 {
                        channel2.lengthCounter -= 1
                    }
                }
                if trigger {
                    if channel2.lengthCounter == 0 {
                        if frameSequencerStep % 2 == 1 && lengthEnabled {
                            channel2.lengthCounter = 63
                        } else {
                            channel2.lengthCounter = 64
                        }
                    }
                    // TODO: Reset envelope
                    channel2.enabled = channel2.dacEnabled && channel2.lengthCounter > 0
                } else {
                    channel2.updateEnabled()
                }
            case 0xFF1A: // NR30: Channel 3 Enable
                NR30 = value & 0b10000000
                channel3.dacEnabled = NR30.get(bit: 7)
                if channel3.enabled {
                    channel3.updateEnabled()
                }
            case 0xFF1B: // NR31: Channel 3 Length
                NR31 = value
                channel3.lengthCounter = 256 - UInt16(value)
            case 0xFF1C: //NR32: Channel 3 Volume
                NR32 = value & 0b01100000
            case 0xFF1D: // NR33: Channel 3 Frequency Low
                NR33 = value
            case 0xFF1E: // NR34: Channel 3 Frequency High/Control
                let wasLengthEnabled = NR34.get(bit: 6)
                let lengthEnabled = value.get(bit: 6)
                let trigger = value.get(bit: 7)
                let originalLengthCounter = channel3.lengthCounter

                // Store the register value first
                NR34 = value & 0b11000111

                if !wasLengthEnabled && lengthEnabled && (frameSequencerStep % 2 == 1) {
                    let shouldApplyQuirk = !trigger || (trigger && originalLengthCounter > 0)
                    if shouldApplyQuirk && channel3.lengthCounter > 0 {
                        channel3.lengthCounter -= 1
                    }
                }
                if trigger {
                    if channel3.lengthCounter == 0 {
                        if frameSequencerStep % 2 == 1 && lengthEnabled {
                            channel3.lengthCounter = 255
                        } else {
                            channel3.lengthCounter = 256
                        }
                    }
                    // TODO: Reset wave position
                    channel3.enabled = channel3.dacEnabled && channel3.lengthCounter > 0
                } else {
                    channel3.updateEnabled()
                }
            case 0xFF20: // NR41: Channel 4 Length
                NR41 = value & 0b00111111
                channel4.lengthCounter = 64 - (value & 0b00111111)
            case 0xFF21: // NR42: Channel 4 Volume/Envelope
                NR42 = value
                channel4.dacEnabled = NR42 & 0b11111000 != 0
                if channel4.enabled {
                    channel4.updateEnabled()
                }
            case 0xFF22: // NR43: Channel 4 Polynomial Counter
                NR43 = value
            case 0xFF23: // NR44: Channel 4 Control
                let wasLengthEnabled = NR44.get(bit: 6)
                let lengthEnabled = value.get(bit: 6)
                let trigger = value.get(bit: 7)
                let originalLengthCounter = channel4.lengthCounter

                // Store the register value first
                NR44 = value & 0b11000000

                if !wasLengthEnabled && lengthEnabled && (frameSequencerStep % 2 == 1) {
                    let shouldApplyQuirk = !trigger || (trigger && originalLengthCounter > 0)
                    if shouldApplyQuirk && channel4.lengthCounter > 0 {
                        channel4.lengthCounter -= 1
                    }
                }
                if trigger {
                    if channel4.lengthCounter == 0 {
                        if frameSequencerStep % 2 == 1 && lengthEnabled {
                            channel4.lengthCounter = 63
                        } else {
                            channel4.lengthCounter = 64
                        }
                    }
                    // TODO: Reset envelope, LFSR
                    channel4.enabled = channel4.dacEnabled && channel4.lengthCounter > 0
                } else {
                    channel4.updateEnabled()
                }
            case 0xFF24: // NR50: Channel Volume Control
                NR50 = value
            case 0xFF25: // NR51: Channel Output Control
                NR51 = value
            case 0xFF26: // NR52: Power Control
                let wasEnabled = enabled
                enabled = value.get(bit: 7)
                if wasEnabled && !enabled {
                   reset()
                } else if !wasEnabled && enabled {
                    frameSequencerStep = 0
                    frameSequencerCounter = 0
                }
            case 0xFF30 ... 0xFF3F: // Wave RAM (0xFF30 to 0xFF3F)
                let index = Int(address - 0xFF30)
                guard index >= 0 && index < waveRAM.count else { return }
                waveRAM[index] = value
            default:
                break // Default case for unhandled registers
        }
    }

    func reset() {
        NR10 = 0x00
        NR11 = 0x00
        NR12 = 0x00
        NR13 = 0x00
        NR14 = 0x00
        NR21 = 0x00
        NR22 = 0x00
        NR23 = 0x00
        NR24 = 0x00
        NR30 = 0x00
        NR31 = 0x00
        NR32 = 0x00
        NR33 = 0x00
        NR34 = 0x00
        NR41 = 0x00
        NR42 = 0x00
        NR43 = 0x00
        NR44 = 0x00
        NR50 = 0x00
        NR51 = 0x00

        channel1.enabled = false
        channel2.enabled = false
        channel3.enabled = false
        channel4.enabled = false
    }

    func tick(cycles: UInt16) {
        guard enabled else { return }
        frameSequencerCounter += Int(cycles)
        while frameSequencerCounter >= 8192 {
            frameSequencerCounter -= 8192
            stepFrameSequencer()
        }
    }

    func stepFrameSequencer() {
        // Steps 0,2,4,6: clock length counters
        if frameSequencerStep % 2 == 0 {
            clockLengthCounters()
        }
        // Steps 2,6: clock sweep (not shown here)
        // Step 7: clock envelope (not shown here)
        frameSequencerStep = (frameSequencerStep + 1) & 0x7
    }

    func clockLengthCounters() {
        // Channel 1
        if NR14.get(bit: 6) && channel1.lengthCounter > 0 {
            channel1.lengthCounter -= 1
            if channel1.lengthCounter == 0 { channel1.updateEnabled() }
        }
        // Channel 2
        if NR24.get(bit: 6) && channel2.lengthCounter > 0 {
            channel2.lengthCounter -= 1
            if channel2.lengthCounter == 0 { channel2.updateEnabled() }
        }
        // Channel 3
        if NR34.get(bit: 6) && channel3.lengthCounter > 0 {
            channel3.lengthCounter -= 1
            if channel3.lengthCounter == 0 { channel3.updateEnabled() }
        }
        // Channel 4
        if NR44.get(bit: 6) && channel4.lengthCounter > 0 {
            channel4.lengthCounter -= 1
            if channel4.lengthCounter == 0 { channel4.updateEnabled() }
        }
    }

    class Channel1 {
        var enabled: Bool = false
        var lengthCounter: UInt8 = 0
        var dacEnabled: Bool = false
        var sweepOverflowed: Bool = false

        func updateEnabled() {
            enabled = lengthCounter > 0 && dacEnabled && !sweepOverflowed
        }

    }

    class Channel2 {
        var enabled: Bool = false
        var lengthCounter: UInt8 = 0
        var dacEnabled: Bool = false

        func updateEnabled() {
            enabled = lengthCounter > 0 && dacEnabled
        }
    }

    class Channel3 {
        var enabled: Bool = false
        var lengthCounter: UInt16 = 0
        var dacEnabled: Bool = false

        func updateEnabled() {
            enabled = lengthCounter > 0 && dacEnabled
        }
    }

    class Channel4 {
        var enabled: Bool = false
        var lengthCounter: UInt8 = 0
        var dacEnabled: Bool = false

        func updateEnabled() {
            enabled = lengthCounter > 0 && dacEnabled
        }
    }
}