import Foundation

// MBC3: Memory Bank Controller 3 with optional Real-Time Clock
// Supports up to 2MB ROM (128 banks), 32KB RAM (4 banks), and RTC registers

class MBC3Cart: MBCCart {
    // ROM and RAM data
    var rom: [UInt8]
    var ram: [UInt8]
    
    // Banking state
    var romBank: UInt8 = 1
    var ramBank: UInt8 = 0
    var ramEnabled: Bool = false
    
    // RTC registers and latching
    struct RTC {
        var seconds: UInt8 = 0      // 0-59
        var minutes: UInt8 = 0      // 0-59
        var hours: UInt8 = 0        // 0-23
        var dayLow: UInt8 = 0       // Lower 8 bits of day counter
        var dayHigh: UInt8 = 0      // Bit 0: Day 9th bit, Bit 6: Halt, Bit 7: Carry
    }
    var rtc = RTC()                // Current RTC registers
    var latchedRTC = RTC()         // Latched copy for reads
    var rtcLatch: Bool = false     // Latch state
    var rtcLastUpdate: Date = Date() // Last time RTC was updated

    // Helper: Update RTC registers based on elapsed time
    func updateRTC() {
        guard (rtc.dayHigh & 0x40) == 0 else { return } // Halted
        let now = Date()
        let elapsed = Int(now.timeIntervalSince(rtcLastUpdate))
        rtcLastUpdate = now
        if elapsed <= 0 { return }
        let totalSeconds = Int(rtc.seconds) + elapsed
        rtc.seconds = UInt8(totalSeconds % 60)
        let totalMinutes = Int(rtc.minutes) + (totalSeconds / 60)
        rtc.minutes = UInt8(totalMinutes % 60)
        let totalHours = Int(rtc.hours) + (totalMinutes / 60)
        rtc.hours = UInt8(totalHours % 24)
        let totalDays = Int(rtc.dayLow) + (totalHours / 24)
        let dayCarry = (Int(rtc.dayHigh & 0x01) << 8) + totalDays
        rtc.dayLow = UInt8(dayCarry & 0xFF)
        rtc.dayHigh = (rtc.dayHigh & 0xFE) | UInt8((dayCarry >> 8) & 0x01)
        if dayCarry > 0x1FF {
            rtc.dayHigh |= 0x80 // Set carry flag
        }
    }

    // Helper: Latch RTC registers
    func latchRTC() {
        updateRTC()
        latchedRTC = rtc
    }
    
    // Init with ROM and RAM sizes
    init(rom: [UInt8], ramSize: Int) {
        self.rom = rom
        self.ram = [UInt8](repeating: 0, count: ramSize)
    }

    // Required by MBCCart protocol
    required convenience init(data: [UInt8]) {
        // Default to 32KB RAM (4 banks) if not specified
        self.init(rom: data, ramSize: 0x8000)
    }
    
    // Read from cartridge
    func read(location: UInt16) -> UInt8 {
        switch location {
        case 0x0000...0x3FFF:
            // Fixed bank 0
            return rom[Int(location)]
        case 0x4000...0x7FFF:
            // Switchable ROM bank
            let bank = max(romBank, 1) & 0x7F
            let offset = Int(bank) * 0x4000 + Int(location - 0x4000)
            let value = rom[safe: offset] ?? 0xFF
            return value
        case 0xA000...0xBFFF:
            if ramEnabled {
                if ramBank <= 0x03 {
                    // RAM bank
                    let offset = Int(ramBank) * 0x2000 + Int(location - 0xA000)
                    return ram[safe: offset] ?? 0xFF
                } else if ramBank >= 0x08 && ramBank <= 0x0C {
                    // RTC register read
                    let rtcReg: UInt8
                    switch ramBank {
                    case 0x08: rtcReg = rtcLatch ? latchedRTC.seconds : rtc.seconds
                    case 0x09: rtcReg = rtcLatch ? latchedRTC.minutes : rtc.minutes
                    case 0x0A: rtcReg = rtcLatch ? latchedRTC.hours : rtc.hours
                    case 0x0B: rtcReg = rtcLatch ? latchedRTC.dayLow : rtc.dayLow
                    case 0x0C: rtcReg = rtcLatch ? latchedRTC.dayHigh : rtc.dayHigh
                    default: rtcReg = 0xFF
                    }
                    return rtcReg
                }
            }
            return 0xFF
        default:
            return 0xFF
        }
    }
    
    // Write to cartridge
    func write(location: UInt16, value: UInt8) {
        switch location {
        case 0x0000...0x1FFF:
            // RAM/RTC enable
            ramEnabled = (value & 0x0F) == 0x0A
        case 0x2000...0x3FFF:
            // ROM bank number (7 bits)
            romBank = value & 0x7F
            if romBank == 0 { romBank = 1 }
        case 0x4000...0x5FFF:
            // RAM bank number or RTC register select
            ramBank = value
        case 0x6000...0x7FFF:
            // Latch clock data
            if value == 0 && rtcLatch {
                rtcLatch = false
            } else if value == 1 && !rtcLatch {
                latchRTC()
                rtcLatch = true
            }
        case 0xA000...0xBFFF:
            if ramEnabled {
                if ramBank <= 0x03 {
                    // RAM write
                    let offset = Int(ramBank) * 0x2000 + Int(location - 0xA000)
                    if offset < ram.count {
                        ram[offset] = value
                    }
                } else if ramBank >= 0x08 && ramBank <= 0x0C {
                    // RTC register write
                    updateRTC()
                    switch ramBank {
                    case 0x08: rtc.seconds = value % 60
                    case 0x09: rtc.minutes = value % 60
                    case 0x0A: rtc.hours = value % 24
                    case 0x0B: rtc.dayLow = value
                    case 0x0C:
                        // Bit 0: Day high, Bit 6: Halt, Bit 7: Carry
                        rtc.dayHigh = value & 0xC1
                        if (rtc.dayHigh & 0x40) != 0 {
                            // Halt: freeze time
                            rtcLastUpdate = Date()
                        }
                    default: break
                    }
                }
            }
        default:
            break
        }
    }
    
    /// Returns the current RAM contents for persistence.
    func getRAM() -> Data? {
        if ram.isEmpty {
            return nil
        }
        return Data(ram)
    }

    /// Loads RAM contents from the given data.
    func setRAM(_ data: Data) {
        if ram.isEmpty {
            return
        }
        for (i, byte) in data.prefix(ram.count).enumerated() {
            ram[i] = byte
        }
    }
}

