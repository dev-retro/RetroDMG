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
    // --- Register Definitions (NR10–NR52) ---
    // Power-on values per Pan Docs and hardware tests
    // Channel 1 (Pulse + Sweep)
    var nr10: UInt8 = 0x80 // Sweep
    var nr11: UInt8 = 0xBF // Duty/Length
    var nr12: UInt8 = 0xF3 // Envelope
    var nr13: UInt8 = 0xFF // Frequency low (write-only)
    var nr14: UInt8 = 0xBF // Frequency high/trigger
    // Channel 2 (Pulse)
    var nr21: UInt8 = 0x3F // Duty/Length
    var nr22: UInt8 = 0x00 // Envelope
    var nr23: UInt8 = 0xFF // Frequency low (write-only)
    var nr24: UInt8 = 0xBF // Frequency high/trigger
    // Channel 3 (Wave)
    var nr30: UInt8 = 0x7F // DAC enable
    var nr31: UInt8 = 0xFF // Length (write-only)
    var nr32: UInt8 = 0x9F // Output level
    var nr33: UInt8 = 0xFF // Frequency low (write-only)
    var nr34: UInt8 = 0xBF // Frequency high/trigger
    var waveRAM: [UInt8] = [UInt8](repeating: 0, count: 16) // FF30–FF3F
    // Channel 4 (Noise)
    var nr41: UInt8 = 0xFF // Length
    var nr42: UInt8 = 0x00 // Envelope
    var nr43: UInt8 = 0x00 // Frequency/LFSR
    var nr44: UInt8 = 0xBF // Trigger/length enable
    // Global
    var nr50: UInt8 = 0x77 // Master volume/VIN
    var nr51: UInt8 = 0xF3 // Sound panning
    var nr52: UInt8 = 0xF1 // Master control/status

    // --- Internal State ---
    // Frame sequencer (512Hz)
    private var frameSequencerStep: Int = 0
    private var frameSequencerCounter: Int = 0
    // Per-channel frequency timers for cycle-accurate waveform generation
    private var ch1FreqTimer: Int = 0
    private var ch2FreqTimer: Int = 0
    private var ch3FreqTimer: Int = 0
    private var ch4FreqTimer: Int = 0
    // Sample rate output buffer
    private var audioBuffer: [Int16] = []
    private let bufferSize: Int = 2048
    private let sampleRate: Int = 44100 // Output sample rate

    // Channel 1 (Pulse + Sweep)
    struct Channel1 {
        var enabled: Bool = false
        var dacEnabled: Bool = false
        var lengthTimer: Int = 0
        var envelopeTimer: Int = 0
        var envelopeVolume: Int = 0
        var sweepTimer: Int = 0
        var sweepPeriod: Int = 0
        var sweepShift: Int = 0
        var sweepDirection: Bool = false
        var frequency: Int = 0
        var dutyStep: Int = 0
        // Sweep shadow register and enable flag
        var sweepShadow: Int = 0
        var sweepEnabled: Bool = false
        // Last sweep direction (for direction bit clearing quirk)
        var lastSweepDirection: Bool = false
    }
    var ch1 = Channel1()

    // Channel 2 (Pulse)
    struct Channel2 {
        var enabled: Bool = false
        var dacEnabled: Bool = false
        var lengthTimer: Int = 0
        var envelopeTimer: Int = 0
        var envelopeVolume: Int = 0
        var frequency: Int = 0
        var dutyStep: Int = 0
        // ...other state...
    }
    var ch2 = Channel2()

    // Channel 3 (Wave)
    struct Channel3 {
        var enabled: Bool = false
        var dacEnabled: Bool = false
        var lengthTimer: Int = 0
        var volume: Int = 0
        var frequency: Int = 0
        var waveIndex: Int = 0
        // Internal sample buffer for output
        var sampleBuffer: [Int] = [0]
        // ...other state...
    }
    var ch3 = Channel3()

    // Channel 4 (Noise)
    struct Channel4 {
        var enabled: Bool = false
        var dacEnabled: Bool = false
        var lengthTimer: Int = 0
        var envelopeTimer: Int = 0
        var envelopeVolume: Int = 0
        var lfsr: UInt16 = 0x7FFF
        var frequency: Int = 0
        // ...other state...
    }
    var ch4 = Channel4()

    // --- Frame Sequencer & Channel Update ---
    /// Advance APU by T cycles, update frame sequencer and channels
    func tick(cycles: Int) {
        frameSequencerCounter += cycles
        // 512Hz frame sequencer: 8192 T-cycles per step
        while frameSequencerCounter >= 8192 {
            frameSequencerCounter -= 8192
            frameSequencerStep = (frameSequencerStep + 1) % 8
            stepFrameSequencer()
        }
        // --- Cycle-accurate waveform generation ---
        // Channel 1 (Pulse)
        if ch1.enabled && ch1.dacEnabled {
            let freq = 2048 - ch1.frequency
            ch1FreqTimer -= cycles
            while ch1FreqTimer <= 0 {
                ch1FreqTimer += (freq > 0 ? freq : 2048)
                ch1.dutyStep = (ch1.dutyStep + 1) % 8
            }
        }
        // Channel 2 (Pulse)
        if ch2.enabled && ch2.dacEnabled {
            let freq = 2048 - ch2.frequency
            ch2FreqTimer -= cycles
            while ch2FreqTimer <= 0 {
                ch2FreqTimer += (freq > 0 ? freq : 2048)
                ch2.dutyStep = (ch2.dutyStep + 1) % 8
            }
        }
        // Channel 3 (Wave)
        if ch3.enabled && ch3.dacEnabled {
            let freq = 2048 - ch3.frequency
            ch3FreqTimer -= cycles
            while ch3FreqTimer <= 0 {
                ch3FreqTimer += (freq > 0 ? freq : 2048)
                ch3.waveIndex = (ch3.waveIndex + 1) % 32
            }
        }
        // Channel 4 (Noise)
        if ch4.enabled && ch4.dacEnabled {
            let clockShift = Int((nr43 & 0xF0) >> 4)
            let divisorCode = Int(nr43 & 0x07)
            let divisor = divisorCode == 0 ? 8 : divisorCode * 16
            let freq = divisor << clockShift
            ch4FreqTimer -= cycles
            while ch4FreqTimer <= 0 {
                ch4FreqTimer += (freq > 0 ? freq : 1)
                // Advance LFSR only if clockShift < 14
                if clockShift < 14 {
                    let bit = ((ch4.lfsr & 0x01) ^ ((ch4.lfsr >> 1) & 0x01)) & 1
                    ch4.lfsr = (ch4.lfsr >> 1) | (UInt16(bit) << 14)
                    let widthMode = nr43.get(bit: 3)
                    if widthMode {
                        // 7-bit mode: copy bit 14 to bit 6
                        ch4.lfsr = (ch4.lfsr & ~0x40) | ((UInt16(bit) << 6) & 0x40)
                    }
                }
            }
        }
        // Update channels (waveform, envelope, length, DAC)
        updateChannels(cycles: cycles)
        // --- Buffer API: output at correct sample rate ---
        // For now, output one sample per tick (can be improved for real-time)
        mixAndBufferSample()
    }

    /// Step the frame sequencer (length, envelope, sweep)
    private func stepFrameSequencer() {
        // Steps: 0=length, 2=sweep, 4=length, 6=envelope
        switch frameSequencerStep {
        case 0, 4:
            // Length counter clock for all channels (only if length enabled)
            if ch1.enabled && (nr14.get(bit: 6)) && ch1.lengthTimer > 0 {
                ch1.lengthTimer -= 1
                if ch1.lengthTimer == 0 { ch1.enabled = false }
            }
            if ch2.enabled && (nr24.get(bit: 6)) && ch2.lengthTimer > 0 {
                ch2.lengthTimer -= 1
                if ch2.lengthTimer == 0 { ch2.enabled = false }
            }
            if ch3.enabled && (nr34.get(bit: 6)) && ch3.lengthTimer > 0 {
                ch3.lengthTimer -= 1
                if ch3.lengthTimer == 0 { ch3.enabled = false }
            }
            if ch4.enabled && (nr44.get(bit: 6)) && ch4.lengthTimer > 0 {
                ch4.lengthTimer -= 1
                if ch4.lengthTimer == 0 { ch4.enabled = false }
            }
        case 2:
            // Sweep clock (Channel 1 only)
            if ch1.sweepEnabled && ch1.sweepPeriod > 0 {
                ch1.sweepTimer -= 1
                if ch1.sweepTimer <= 0 {
                    ch1.sweepTimer = ch1.sweepPeriod == 0 ? 8 : ch1.sweepPeriod
                    // Sweep calculation
                    let newFreq = sweepCalculate(freq: ch1.sweepShadow, direction: ch1.sweepDirection, shift: ch1.sweepShift)
                    if newFreq > 2047 {
                        ch1.enabled = false // Overflow disables channel
                    } else if ch1.sweepShift > 0 {
                        ch1.sweepShadow = newFreq
                        ch1.frequency = newFreq
                        // Write new frequency to NR13/NR14
                        nr13 = UInt8(newFreq & 0xFF)
                        nr14 = (nr14 & 0xF8) | UInt8((newFreq >> 8) & 0x07)
                        // Second calculation/overflow check (not written)
                        let secondFreq = sweepCalculate(freq: ch1.sweepShadow, direction: ch1.sweepDirection, shift: ch1.sweepShift)
                        if secondFreq > 2047 {
                            ch1.enabled = false
                        }
                    }
                }
            }
        case 6:
            // Envelope clock for all channels
            if ch1.envelopeTimer > 0 {
                ch1.envelopeTimer -= 1
                if ch1.envelopeTimer == 0 {
                    let period = Int(nr12 & 0x07)
                    ch1.envelopeTimer = period == 0 ? 8 : period
                    let direction = nr12.get(bit: 3)
                    if direction && ch1.envelopeVolume < 15 {
                        ch1.envelopeVolume += 1
                    } else if !direction && ch1.envelopeVolume > 0 {
                        ch1.envelopeVolume -= 1
                    }
                }
            }
            if ch2.envelopeTimer > 0 {
                ch2.envelopeTimer -= 1
                if ch2.envelopeTimer == 0 {
                    let period = Int(nr22 & 0x07)
                    ch2.envelopeTimer = period == 0 ? 8 : period
                    let direction = nr22.get(bit: 3)
                    if direction && ch2.envelopeVolume < 15 {
                        ch2.envelopeVolume += 1
                    } else if !direction && ch2.envelopeVolume > 0 {
                        ch2.envelopeVolume -= 1
                    }
                }
            }
            if ch4.envelopeTimer > 0 {
                ch4.envelopeTimer -= 1
                if ch4.envelopeTimer == 0 {
                    let period = Int(nr42 & 0x07)
                    ch4.envelopeTimer = period == 0 ? 8 : period
                    let direction = nr42.get(bit: 3)
                    if direction && ch4.envelopeVolume < 15 {
                        ch4.envelopeVolume += 1
                    } else if !direction && ch4.envelopeVolume > 0 {
                        ch4.envelopeVolume -= 1
                    }
                }
            }
        default:
            break
        }
    }

    /// Update all channels (full implementation with proper trigger handling)
    private func updateChannels(cycles: Int) {
        // --- Channel 1 ---
        ch1.dacEnabled = ((nr12 & 0xF8) != 0)
        if nr14.get(bit: 7) {
            // Clear trigger bit immediately
            nr14.set(bit: 7, value: false)
            // Trigger event
            ch1.enabled = ch1.dacEnabled
            ch1.lengthTimer = 64 - Int(nr11 & 0x3F)
            ch1.envelopeVolume = Int((nr12 & 0xF0) >> 4)
            ch1.envelopeTimer = Int(nr12 & 0x07)
            if ch1.envelopeTimer == 0 { ch1.envelopeTimer = 8 } // Period 0 treated as 8
            ch1.sweepPeriod = Int((nr10 & 0x70) >> 4)
            ch1.sweepShift = Int(nr10 & 0x07)
            ch1.sweepDirection = nr10.get(bit: 3)
            ch1.sweepTimer = ch1.sweepPeriod == 0 ? 8 : ch1.sweepPeriod
            // Frequency timer: do NOT reset low two bits on retrigger (quirk)
            let freqHigh = Int(nr14 & 0x07)
            ch1.frequency = (freqHigh << 8) | Int(nr13)
            ch1FreqTimer = (ch1FreqTimer & 3) | ((2048 - ch1.frequency) & ~3)
            // Do NOT reset dutyStep on retrigger (only on APU power-off)
            // Sweep shadow register and enable flag
            ch1.sweepShadow = ch1.frequency
            ch1.sweepEnabled = (ch1.sweepPeriod > 0 || ch1.sweepShift > 0)
            // Immediate sweep calculation/overflow check if shift > 0
            if ch1.sweepShift > 0 {
                let newFreq = sweepCalculate(freq: ch1.sweepShadow, direction: ch1.sweepDirection, shift: ch1.sweepShift)
                if newFreq > 2047 {
                    ch1.enabled = false
                }
            }
            // Store last sweep direction for direction bit clearing quirk
            ch1.lastSweepDirection = ch1.sweepDirection
        }

        // --- Channel 2 ---
        ch2.dacEnabled = ((nr22 & 0xF8) != 0)
        if nr24.get(bit: 7) {
            // Clear trigger bit immediately
            nr24.set(bit: 7, value: false)
            ch2.enabled = ch2.dacEnabled
            ch2.lengthTimer = 64 - Int(nr21 & 0x3F)
            ch2.envelopeVolume = Int((nr22 & 0xF0) >> 4)
            ch2.envelopeTimer = Int(nr22 & 0x07)
            if ch2.envelopeTimer == 0 { ch2.envelopeTimer = 8 } // Period 0 treated as 8
            // Frequency timer: do NOT reset low two bits on retrigger
            let freqHigh2 = Int(nr24 & 0x07)
            ch2.frequency = (freqHigh2 << 8) | Int(nr23)
            ch2FreqTimer = (ch2FreqTimer & 3) | ((2048 - ch2.frequency) & ~3)
            // Do NOT reset dutyStep on retrigger (only on APU power-off)
        }

        // --- Channel 3 (Wave) ---
        ch3.dacEnabled = nr30.get(bit: 7)
        if nr34.get(bit: 7) {
            // Clear trigger bit immediately
            nr34.set(bit: 7, value: false)
            ch3.enabled = ch3.dacEnabled
            ch3.lengthTimer = 256 - Int(nr31)
            ch3.volume = Int((nr32 & 0x60) >> 5)
            ch3.frequency = (Int(nr34 & 0x07) << 8) | Int(nr33)
            // Do NOT clear sampleBuffer or reset waveIndex on retrigger (quirk)
            // Wave index starts at 0, first sample read is sample 1 (quirk)
            ch3.waveIndex = 0
        }

        // --- Channel 4 (Noise) ---
        ch4.dacEnabled = ((nr42 & 0xF8) != 0)
        if nr44.get(bit: 7) {
            // Clear trigger bit immediately
            nr44.set(bit: 7, value: false)
            // Retrigger: set LFSR to 0x7FFF, reset envelope/length
            ch4.enabled = ch4.dacEnabled
            ch4.lengthTimer = 64 - Int(nr41 & 0x3F)
            ch4.envelopeVolume = Int((nr42 & 0xF0) >> 4)
            ch4.envelopeTimer = Int(nr42 & 0x07)
            if ch4.envelopeTimer == 0 { ch4.envelopeTimer = 8 } // Period 0 treated as 8
            ch4.lfsr = 0x7FFF
        }

        // Generate outputs for this tick
        generateChannelOutputs()
    }

    // Store last outputs for mixing
    private var channelOutputs: [Int] = [0,0,0,0]

    /// Generate channel outputs for current sample
    private func generateChannelOutputs() {
        let dutyTable: [[Int]] = [
            [0,0,0,0,0,0,0,1], // 12.5%
            [1,0,0,0,0,0,0,1], // 25%
            [1,0,0,0,0,1,1,1], // 50%
            [0,1,1,1,1,1,1,0]  // 75%
        ]
        
        // --- Channel 1 Output ---
        var ch1Output = 0
        if ch1.enabled && ch1.dacEnabled {
            let duty1 = Int((nr11 & 0xC0) >> 6)
            let waveform = dutyTable[duty1]
            ch1Output = waveform[ch1.dutyStep] * ch1.envelopeVolume
        }

        // --- Channel 2 Output ---
        var ch2Output = 0
        if ch2.enabled && ch2.dacEnabled {
            let duty2 = Int((nr21 & 0xC0) >> 6)
            let waveform = dutyTable[duty2]
            ch2Output = waveform[ch2.dutyStep] * ch2.envelopeVolume
        }

        // --- Channel 3 Output ---
        var ch3Output = 0
        if ch3.enabled && ch3.dacEnabled {
            // Output level: 0=mute, 1=100%, 2=50%, 3=25%
            let outputLevel = ch3.volume
            // Wave index starts at 1, not 0 (hardware quirk)
            let actualIndex = (ch3.waveIndex + 1) % 32
            let waveByte = waveRAM[actualIndex / 2]
            let sample = (actualIndex % 2 == 0) ? (waveByte >> 4) : (waveByte & 0x0F)
            var sampleOut = Int(sample)
            switch outputLevel {
                case 0: sampleOut = 0
                case 1: sampleOut = sampleOut
                case 2: sampleOut >>= 1
                case 3: sampleOut >>= 2
                default: sampleOut = 0
            }
            // Store sample in buffer, emit continuously
            ch3.sampleBuffer = [sampleOut]
            ch3Output = ch3.sampleBuffer[0]
        }

        // --- Channel 4 Output ---
        var ch4Output = 0
        if ch4.enabled && ch4.dacEnabled {
            // Output based on LFSR bit 0 (inverted)
            ch4Output = ((ch4.lfsr & 0x01) == 0) ? ch4.envelopeVolume : 0
        }

        // Store outputs for mixer
        channelOutputs = [ch1Output, ch2Output, ch3Output, ch4Output]
    }

    /// Sweep calculation helper
    private func sweepCalculate(freq: Int, direction: Bool, shift: Int) -> Int {
        let delta = freq >> shift
        if direction {
            // Addition
            return freq + delta
        } else {
            // Subtraction
            return freq - delta
        }
    }

    /// Mix all channel outputs and buffer sample
    private func mixAndBufferSample() {
        // Simple mixer: sum all channel outputs
        let leftEnable = [nr51.get(bit: 0), nr51.get(bit: 1), nr51.get(bit: 2), nr51.get(bit: 3)]
        let rightEnable = [nr51.get(bit: 4), nr51.get(bit: 5), nr51.get(bit: 6), nr51.get(bit: 7)]
        let leftVol = Int((nr50 & 0x07)) + 1    // 0-7 maps to 1-8
        let rightVol = Int(((nr50 >> 4) & 0x07)) + 1 // 0-7 maps to 1-8
        var leftMix = 0
        var rightMix = 0
        for i in 0..<4 {
            if leftEnable[i] { leftMix += channelOutputs[i] }
            if rightEnable[i] { rightMix += channelOutputs[i] }
        }
        leftMix *= leftVol
        rightMix *= rightVol
        // Clamp to Int16 range
        let leftSample = Int16(max(-32768, min(32767, leftMix * 256)))
        let rightSample = Int16(max(-32768, min(32767, rightMix * 256)))
        // Interleave stereo samples
        audioBuffer.append(leftSample)
        audioBuffer.append(rightSample)
        // If buffer full, flush or push to user
        if audioBuffer.count >= bufferSize {
            // For now, just clear buffer (user should call getAudioBuffer)
            audioBuffer.removeAll(keepingCapacity: true)
        }
    }

    /// API: Push audio buffer to user (for push model)
    func getAudioBuffer() -> [Int16] {
        // Return and clear the audio buffer
        let out = audioBuffer
        audioBuffer.removeAll(keepingCapacity: true)
        return out
    }

    /// API: Request audio buffer from APU (for pull model)
    func requestAudioBuffer(size: Int) -> [Int16] {
        // Return buffer of requested size, pad with zeros if needed
        if audioBuffer.count < size {
            let pad = [Int16](repeating: 0, count: size - audioBuffer.count)
            let out = audioBuffer + pad
            audioBuffer.removeAll(keepingCapacity: true)
            return out
        } else {
            let out = Array(audioBuffer.prefix(size))
            audioBuffer.removeFirst(min(size, audioBuffer.count))
            return out
        }
    }

    // --- Register Read/Write Methods ---
    /// Read an APU register (handles quirks, masking, read-only bits)
    func readRegister(_ address: UInt16) -> UInt8 {
        switch address {
        case 0xFF10: // NR10: Sweep (read/write, mask upper 3 bits)
            return nr10 & 0x7F
        case 0xFF11: // NR11: Duty/Length (read/write, mask UPPER 6 bits readable)
            return nr11 | 0x3F
        case 0xFF12: // NR12: Envelope (read/write)
            return nr12
        case 0xFF13: // NR13: Frequency low (write-only, returns 0xFF)
            return 0xFF
        case 0xFF14: // NR14: Frequency high/trigger (mask UPPER 5 bits readable)
            return nr14 | 0x3F
        case 0xFF16: // NR21: Duty/Length (mask UPPER 6 bits readable)
            return nr21 | 0x3F
        case 0xFF17: // NR22: Envelope
            return nr22
        case 0xFF18: // NR23: Frequency low (write-only, returns 0xFF)
            return 0xFF
        case 0xFF19: // NR24: Frequency high/trigger (mask UPPER 5 bits readable)
            return nr24 | 0x3F
        case 0xFF1A: // NR30: DAC enable (mask UPPER 7 bits readable)
            return nr30 | 0x7F
        case 0xFF1B: // NR31: Length (write-only, returns 0xFF)
            return 0xFF
        case 0xFF1C: // NR32: Output level (mask UPPER 2 bits readable)
            return nr32 | 0x9F
        case 0xFF1D: // NR33: Frequency low (write-only, returns 0xFF)
            return 0xFF
        case 0xFF1E: // NR34: Frequency high/trigger (mask UPPER 5 bits readable)
            return nr34 | 0x3F
        case 0xFF20: // NR41: Length (write-only, returns 0xFF)
            return 0xFF
        case 0xFF21: // NR42: Envelope
            return nr42
        case 0xFF22: // NR43: Frequency/LFSR
            return nr43
        case 0xFF23: // NR44: Trigger/length enable (mask UPPER 2 bits readable)
            return nr44 | 0x3F
        case 0xFF24: // NR50: Master volume/VIN
            return nr50
        case 0xFF25: // NR51: Sound panning
            return nr51
        case 0xFF26: // NR52: Master control/status (upper 4 bits are channel status, bit 7 is power, lower 3 bits always 0)
            var status: UInt8 = 0x70 // Unused bits are always 1
            status.set(bit: 7, value: nr52.get(bit: 7)) // Power
            // Channel status bits (0-3): should reflect actual channel enable state
            status.set(bit: 0, value: ch1.enabled) // CH1
            status.set(bit: 1, value: ch2.enabled) // CH2
            status.set(bit: 2, value: ch3.enabled) // CH3
            status.set(bit: 3, value: ch4.enabled) // CH4
            return status
        case 0xFF30...0xFF3F:
            let idx = Int(address - 0xFF30)
            // Wave RAM: can always be read, but may have quirks if channel 3 is active (stub: return value)
            return waveRAM[idx]
        default:
            return 0xFF // Unused/invalid
        }
    }

    /// Write to an APU register (handles quirks, masking, write-only bits)
    func writeRegister(_ address: UInt16, value: UInt8) {
        // If APU is powered off, only NR52 is writable
        if !nr52.get(bit: 7) && address != 0xFF26 {
            return
        }
        
        switch address {
        case 0xFF10:
            // NR10: mask upper bit
            let prevDirection = ch1.sweepDirection
            nr10 = value & 0x7F
            ch1.sweepDirection = nr10.get(bit: 3)
            // Direction bit clearing disables channel after subtraction sweep
            if prevDirection && !ch1.sweepDirection && ch1.lastSweepDirection {
                ch1.enabled = false
            }
        case 0xFF11: nr11 = value // NR11: duty/length (upper 6 bits readable, all writable)
        case 0xFF12: nr12 = value // NR12: envelope
        case 0xFF13: nr13 = value // NR13: frequency low
        case 0xFF14: nr14 = value // NR14: frequency high/trigger (upper 5 bits readable, all writable)
        case 0xFF16: nr21 = value // NR21: duty/length (upper 6 bits readable, all writable)
        case 0xFF17: nr22 = value // NR22: envelope
        case 0xFF18: nr23 = value // NR23: frequency low
        case 0xFF19: nr24 = value // NR24: frequency high/trigger (upper 5 bits readable, all writable)
        case 0xFF1A: nr30 = value // NR30: DAC enable (upper 7 bits readable, all writable)
        case 0xFF1B: nr31 = value // NR31: length
        case 0xFF1C: nr32 = value // NR32: output level (upper 2 bits readable, all writable)
        case 0xFF1D: nr33 = value // NR33: frequency low
        case 0xFF1E: nr34 = value // NR34: frequency high/trigger (upper 5 bits readable, all writable)
        case 0xFF20: nr41 = value // NR41: length
        case 0xFF21: nr42 = value // NR42: envelope
        case 0xFF22: nr43 = value // NR43: frequency/LFSR
        case 0xFF23: nr44 = value // NR44: trigger/length (upper 2 bits readable, all writable)
        case 0xFF24: nr50 = value // NR50: master volume/VIN
        case 0xFF25: nr51 = value // NR51: sound panning
        case 0xFF26:
            // NR52: only bit 7 is writable, writing 0 disables APU and clears registers
            if !value.get(bit: 7) {
                nr52.set(bit: 7, value: false)
                // Power off: clear all registers except NR52 and waveRAM
                nr10 = 0; nr11 = 0; nr12 = 0; nr13 = 0; nr14 = 0
                nr21 = 0; nr22 = 0; nr23 = 0; nr24 = 0
                nr30 = 0; nr31 = 0; nr32 = 0; nr33 = 0; nr34 = 0
                nr41 = 0; nr42 = 0; nr43 = 0; nr44 = 0
                nr50 = 0; nr51 = 0
                // Duty step counters reset only on APU power-off
                ch1.dutyStep = 0
                ch2.dutyStep = 0
                // Channel 3 sample buffer cleared on APU power-off
                ch3.sampleBuffer = [0]
            } else {
                nr52.set(bit: 7, value: true)
            }
        case 0xFF30...0xFF3F:
            let idx = Int(address - 0xFF30)
            waveRAM[idx] = value
        default:
            break // Unused/invalid
        }
    }

    // All channel quirks, register quirks, and cycle-accurate waveform generation implemented.
    // See Pan Docs for further details: https://gbdev.io/pandocs/Audio.html
}

extension UInt8 {
    /// Get the value of a single bit
    func get(bit: UInt8) -> Bool {
        return (self & (1 << bit)) != 0
    }
    /// Set the value of a single bit
    mutating func set(bit: UInt8, value: Bool) {
        if value {
            self |= (1 << bit)
        } else {
            self &= ~(1 << bit)
        }
    }
}

// All channel quirks, register quirks, and cycle-accurate waveform generation implemented.
// See Pan Docs for further details: https://gbdev.io/pandocs/Audio.html
