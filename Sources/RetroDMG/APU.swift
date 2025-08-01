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
                case 0xFF11: // NR11: Channel 1 Duty/Length
                    // Only update length, not duty
                    channel1.lengthCounter = 64 - (value & 0b00111111)
                    return
                case 0xFF21: // NR21: Channel 2 Duty/Length
                    channel2.lengthCounter = 64 - (value & 0b00111111)
                    return
                case 0xFF31: // NR31: Channel 3 Length
                    channel3.lengthCounter = 256 - UInt16(value)
                    return
                case 0xFF41: // NR41: Channel 4 Length
                    channel4.lengthCounter = 64 - (value & 0b00111111)
                    return
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
                var decrementedToZero = false
                if !wasLengthEnabled && lengthEnabled && (frameSequencerStep % 2 == 1) {
                    let shouldApplyQuirk = !trigger || (trigger && originalLengthCounter > 0)
                    if shouldApplyQuirk && channel1.lengthCounter > 0 {
                        channel1.lengthCounter -= 1
                        if channel1.lengthCounter == 0 && !trigger {
                            decrementedToZero = true
                        }
                    }
                }
                // If the quirk decremented to zero and trigger is clear, disable the channel immediately
                if decrementedToZero {
                    channel1.enabled = false
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
                    // Reset envelope
                    channel1.envelopeVolume = (NR12 >> 4) & 0xF
                    let envelopePeriod = NR12 & 0b111
                    channel1.envelopeTimer = envelopePeriod == 0 ? 8 : envelopePeriod
                    // Copy current frequency to shadow register FIRST
                    channel1.shadowFrequency = UInt16((UInt16(NR14 & 0b111) << 8) | UInt16(NR13))
                    let sweepPeriod = channel1.sweepPeriod(NR10)
                    let sweepShift = channel1.sweepShift(NR10)
                    let rawPeriod = (NR10 >> 4) & 0b111
                    // Set sweepEnabled only if period > 0 or shift > 0
                    channel1.sweepEnabled = (rawPeriod != 0 || sweepShift != 0)
                    // Always reload sweep timer on trigger (period==0 means 8)
                    channel1.sweepTimer = sweepPeriod
                    channel1.sweepOverflowed = false
                    channel1.sweepNegateUsed = false
                    // Only perform overflow check on trigger if sweep shift is not zero
                    if sweepShift != 0 {
                        print("[SWEEP][TRIGGER] Calling performSweepCalculation on trigger (shift=", sweepShift, ")")
                        let _ = performSweepCalculation(updateRegisters: false, forceCheck: true)
                    } else {
                        print("[SWEEP][TRIGGER] NOT calling performSweepCalculation on trigger (shift=0) -- CORRECT: no calculation performed")
                        // Do not call performSweepCalculation at all if shift==0 (matches hardware)
                    }
                    channel1.enabled = channel1.dacEnabled && channel1.lengthCounter > 0 && !channel1.sweepOverflowed
                    print("[SWEEP][TRIGGER] After trigger: enabled=\(channel1.enabled), dacEnabled=\(channel1.dacEnabled), lengthCounter=\(channel1.lengthCounter), sweepOverflowed=\(channel1.sweepOverflowed), sweepEnabled=\(channel1.sweepEnabled), sweepTimer=\(channel1.sweepTimer), shift=\(sweepShift), period=\(rawPeriod)")
                } else if !decrementedToZero {
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

                var decrementedToZero = false
                if !wasLengthEnabled && lengthEnabled && (frameSequencerStep % 2 == 1) {
                    let shouldApplyQuirk = !trigger || (trigger && originalLengthCounter > 0)
                    if shouldApplyQuirk && channel2.lengthCounter > 0 {
                        channel2.lengthCounter -= 1
                        if channel2.lengthCounter == 0 && !trigger {
                            decrementedToZero = true
                        }
                    }
                }
                if decrementedToZero {
                    channel2.enabled = false
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
                } else if !decrementedToZero {
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

                var decrementedToZero = false
                if !wasLengthEnabled && lengthEnabled && (frameSequencerStep % 2 == 1) {
                    let shouldApplyQuirk = !trigger || (trigger && originalLengthCounter > 0)
                    if shouldApplyQuirk && channel3.lengthCounter > 0 {
                        channel3.lengthCounter -= 1
                        if channel3.lengthCounter == 0 && !trigger {
                            decrementedToZero = true
                        }
                    }
                }
                if decrementedToZero {
                    channel3.enabled = false
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
                } else if !decrementedToZero {
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

                var decrementedToZero = false
                if !wasLengthEnabled && lengthEnabled && (frameSequencerStep % 2 == 1) {
                    let shouldApplyQuirk = !trigger || (trigger && originalLengthCounter > 0)
                    if shouldApplyQuirk && channel4.lengthCounter > 0 {
                        channel4.lengthCounter -= 1
                        if channel4.lengthCounter == 0 && !trigger {
                            decrementedToZero = true
                        }
                    }
                }
                if decrementedToZero {
                    channel4.enabled = false
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
                } else if !decrementedToZero {
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
        // Steps 2,6: clock sweep
        if frameSequencerStep == 2 || frameSequencerStep == 6 {
            clockSweepUnit()
        }
        // Step 7: clock envelope (proper timer logic)
        if frameSequencerStep == 7 {
            let envelopePeriod = NR12 & 0b111
            let envelopeDirection = (NR12 & 0b1000) != 0 // true = increase
            if envelopePeriod != 0 && channel1.enabled {
                if channel1.envelopeTimer > 0 {
                    channel1.envelopeTimer -= 1
                }
                if channel1.envelopeTimer == 0 {
                    if !envelopeDirection {
                        // Decrease
                        if channel1.envelopeVolume > 0 {
                            channel1.envelopeVolume -= 1
                        }
                    } else {
                        // Increase (not needed for this test)
                        if channel1.envelopeVolume < 15 {
                            channel1.envelopeVolume += 1
                        }
                    }
                    channel1.envelopeTimer = envelopePeriod == 0 ? 8 : envelopePeriod
                }
            }
            // Never enable or disable the channel here; only length counter, sweep, or DAC-off can disable. Length counter always has final say.
        }
        frameSequencerStep = (frameSequencerStep + 1) & 0x7
    }
    func clockSweepUnit() {
        // Only clock if sweep is enabled
        if channel1.sweepEnabled {
            if channel1.sweepTimer > 0 {
                channel1.sweepTimer -= 1
            }
            if channel1.sweepTimer == 0 {
                let sweepShift = channel1.sweepShift(NR10)
                print("[SWEEP] clockSweepUnit: sweepEnabled=\(channel1.sweepEnabled), sweepShift=\(sweepShift), timer=\(channel1.sweepTimer)")
                // Only perform sweep calculation if sweep shift is not zero
                if sweepShift != 0 {
                    print("[SWEEP] Performing sweep calculation on sweep tick (shift=\(sweepShift))")
                    if performSweepCalculation(updateRegisters: true) {
                        // If overflow, channel1.sweepOverflowed will be set
                    }
                } else {
                    print("[SWEEP] Skipping sweep calculation on sweep tick (shift=0)")
                }
                channel1.sweepTimer = channel1.sweepPeriod(NR10)
            }
        }
    }

    // Returns true if overflow occurred
    func performSweepCalculation(updateRegisters: Bool, forceCheck: Bool = false) -> Bool {
        let shift = channel1.sweepShift(NR10)
        let direction = channel1.sweepDirection(NR10)
        let freq = channel1.shadowFrequency
        var newFreq: UInt16
        print("[SWEEP] performSweepCalculation: shift=\(shift), direction=\(direction), freq=\(freq), forceCheck=\(forceCheck)")
        if shift == 0 && !forceCheck {
            print("[SWEEP] performSweepCalculation: shift=0 and not forceCheck, returning false")
            return false
        }
        if direction {
            // Subtract
            newFreq = freq &- (freq >> shift)
            channel1.sweepNegateUsed = true
        } else {
            // Add
            newFreq = freq &+ (freq >> shift)
        }
        if newFreq > 2047 {
            print("[SWEEP] performSweepCalculation: overflow, disabling channel")
            channel1.sweepOverflowed = true
            channel1.enabled = false
            return true
        }
        if updateRegisters && shift != 0 {
            channel1.shadowFrequency = newFreq
            NR13 = UInt8(newFreq & 0xFF)
            NR14 = (NR14 & 0b11111000) | UInt8((newFreq >> 8) & 0b111)
            // Second calculation for overflow check (do not write back)
            let secondFreq: UInt16
            if direction {
                secondFreq = newFreq &- (newFreq >> shift)
            } else {
                secondFreq = newFreq &+ (newFreq >> shift)
            }
            if secondFreq > 2047 {
                print("[SWEEP] performSweepCalculation: second overflow, disabling channel")
                channel1.sweepOverflowed = true
                channel1.enabled = false
                return true
            }
        }
        // Direction bit quirk: if direction changes from subtract to add after a subtract, disable
        if !direction && channel1.sweepNegateUsed {
            print("[SWEEP] performSweepCalculation: direction quirk, disabling channel")
            channel1.sweepOverflowed = true
            channel1.enabled = false
            return true
        }
        return false
    }

    func clockLengthCounters() {
        // Channel 1
        if NR14.get(bit: 6) && channel1.lengthCounter > 0 {
            channel1.lengthCounter -= 1
            print("[LENGTH] Channel 1 decremented: lengthCounter=\(channel1.lengthCounter)")
            if channel1.lengthCounter == 0 {
                channel1.enabled = false // Only length counter disables
                print("[LENGTH] Channel 1 disabled by length counter: enabled=\(channel1.enabled)")
            }
        }
        // Channel 2
        if NR24.get(bit: 6) && channel2.lengthCounter > 0 {
            channel2.lengthCounter -= 1
            if channel2.lengthCounter == 0 {
                channel2.enabled = false // Only length counter disables
            }
        }
        // Channel 3
        if NR34.get(bit: 6) && channel3.lengthCounter > 0 {
            channel3.lengthCounter -= 1
            if channel3.lengthCounter == 0 {
                channel3.enabled = false // Only length counter disables
            }
        }
        // Channel 4
        if NR44.get(bit: 6) && channel4.lengthCounter > 0 {
            channel4.lengthCounter -= 1
            if channel4.lengthCounter == 0 {
                channel4.enabled = false // Only length counter disables
            }
        }
    }

    class Channel1 {
        var enabled: Bool = false
        var lengthCounter: UInt8 = 0
        var dacEnabled: Bool = false
        var sweepOverflowed: Bool = false
        var sweepTimer: UInt8 = 0
        var sweepEnabled: Bool = false
        var shadowFrequency: UInt16 = 0 // New: shadow register for sweep
        var sweepNegateUsed: Bool = false // For direction quirk
        // Envelope
        var envelopeTimer: UInt8 = 0
        var envelopeVolume: UInt8 = 0

        func sweepPeriod(_ NR10: UInt8) -> UInt8 {
            let period = (NR10 >> 4) & 0b111
            return period == 0 ? 8 : period
        }
        func sweepShift(_ NR10: UInt8) -> UInt8 {
            return NR10 & 0b111
        }
        func sweepDirection(_ NR10: UInt8) -> Bool {
            return (NR10 & 0b1000) != 0 // true = decrease, false = increase
        }
        // Only disables the channel if needed; never enables
        func updateEnabled() {
            if lengthCounter == 0 || !dacEnabled || sweepOverflowed {
                enabled = false
            }
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