import Foundation

/// MBC2: Memory Bank Controller 2
///
/// Supports up to 256KB ROM (16 banks), 512 x 4-bit RAM (internal, 4 bits per cell).
///
/// - ROM banking: 16 banks, selected via writes to 0x2000–0x3FFF (bit 8 of address must be set).
/// - RAM: 512 bytes, only lower nibble used, upper nibble always set to 1.
/// - RAM enable: Only enabled if lower 4 bits of value written to 0x0000–0x1FFF are 0x0A.
/// - No external RAM.
/// - Battery-backed RAM supported via API.
///
/// Use `getRAM()` and `setRAM(_:)` for persistence.
///
/// Reference: [GBDEV MBC2 documentation](https://gbdev.io/pandocs/MBC2.html)

class MBC2Cart: MBCCart {
    /// ROM data
    var rom: [UInt8]
    /// Internal RAM (512 bytes, only lower nibble used)
    var ram: [UInt8]
    /// Current ROM bank (1–15)
    var romBank: UInt8 = 1
    /// RAM enable flag
    var ramEnabled: Bool = false

    /// Initializes an MBC2 cartridge with the given ROM data.
    /// - Parameter rom: The ROM data for the cartridge.
    init(rom: [UInt8]) {
        self.rom = rom
        self.ram = [UInt8](repeating: 0x0F, count: 512) // 0x0F: upper nibble always set
    }

    /// Returns the current RAM contents for persistence.
    /// - Returns: A `Data` object containing 512 bytes, each with upper nibble set to 1.
    func getRAM() -> Data {
        // Only lower nibble is meaningful, upper nibble always set
        return Data(ram.map { $0 | 0xF0 })
    }

    /// Loads RAM contents from the given data.
    /// - Parameter data: A `Data` object containing up to 512 bytes. Only lower nibble is stored.
    func setRAM(_ data: Data) {
        // Only lower nibble is stored
        for (i, byte) in data.prefix(512).enumerated() {
            ram[i] = byte & 0x0F
        }
    }

    /// Required initializer for MBCCart protocol.
    /// - Parameter data: The ROM data for the cartridge.
    required convenience init(data: [UInt8]) {
        self.init(rom: data)
    }

    /// Reads a byte from the cartridge at the given address.
    /// - Parameter location: The address to read from.
    /// - Returns: The value read from ROM or RAM, or 0xFF if out of bounds or disabled.
    func read(location: UInt16) -> UInt8 {
        switch location {
        case 0x0000...0x3FFF:
            // Bank 0
            return rom[Int(location)]
        case 0x4000...0x7FFF:
            // Switchable ROM bank
            let bank = romBank & 0x0F
            let offset = Int(bank) * 0x4000 + Int(location - 0x4000)
            return rom[safe: offset] ?? 0xFF
        case 0xA000...0xA1FF:
            if ramEnabled {
                let addr = Int(location - 0xA000) & 0x1FF
                return ram[addr] | 0xF0 // upper nibble always set
            }
            return 0xFF
        default:
            return 0xFF
        }
    }

    /// Writes a byte to the cartridge at the given address.
    /// - Parameters:
    ///   - location: The address to write to.
    ///   - value: The value to write.
    func write(location: UInt16, value: UInt8) {
        switch location {
        case 0x0000...0x1FFF:
            // RAM enable/disable (only if lower 4 bits == 0x0A)
            ramEnabled = (value & 0x0F) == 0x0A
        case 0x2000...0x3FFF:
            // ROM bank select (only if bit 8 of address is set)
            if (location & 0x0100) != 0 {
                romBank = value & 0x0F
                if romBank == 0 { romBank = 1 }
            }
        case 0xA000...0xA1FF:
            if ramEnabled {
                let addr = Int(location - 0xA000) & 0x1FF
                ram[addr] = value & 0x0F // only lower nibble stored
            }
        default:
            break
        }
    }
}

