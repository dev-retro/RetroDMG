import Foundation

/// MBC5: Memory Bank Controller 5
///
/// Supports up to 8MB ROM (512 banks), up to 128KB RAM (16 banks), and optional rumble feature.
///
/// - ROM banking: 9 bits (0x2000–0x2FFF for lower 8, 0x3000–0x3FFF for bit 9)
/// - RAM banking: 4 bits (0x4000–0x5FFF)
/// - Rumble: 0x6000–0x7FFF (bit 3)
/// - RAM enable: 0x0000–0x1FFF (0x0A in lower nibble)
/// - Battery-backed RAM supported via API.
///
/// Use `getRAM()`, `setRAM(_:)`, `getRumble()`, and `setRumble(_:)` for persistence and control.
///
/// Reference: [GBDEV MBC5 documentation](https://gbdev.io/pandocs/MBC5.html)
///
/// - Note: For rumble cartridges, bit 3 of the RAM bank register controls the rumble motor. See [Pokémon Pinball](https://gbdev.io/pandocs/MBC5.html#rumble) for usage details.
///
/// - SeeAlso: `MBCCart`, `MBCType`, `ROMSize`, `RAMSize`
class MBC5Cart: MBCCart {
    /// ROM data
    var rom: [UInt8]
    /// RAM data (up to 128KB)
    var ram: [UInt8]
    /// Current ROM bank (0–511)
    var romBank: UInt16 = 1
    /// Current RAM bank (0–15)
    var ramBank: UInt8 = 0
    /// RAM enable flag
    var ramEnabled: Bool = false
    /// Rumble state
    var rumbleEnabled: Bool = false

    /// Initializes an MBC5 cartridge with the given ROM and RAM size.
    /// - Parameters:
    ///   - rom: The ROM data for the cartridge.
    ///   - ramSize: The RAM size in bytes.
    init(rom: [UInt8], ramSize: Int) {
        self.rom = rom
        self.ram = [UInt8](repeating: 0, count: ramSize)
    }

    /// Required initializer for MBCCart protocol.
    /// - Parameter data: The ROM data for the cartridge.
    required convenience init(data: [UInt8]) {
        // Default to 128KB RAM (16 banks) if not specified
        self.init(rom: data, ramSize: 0x20000)
    }

    /// Returns the current RAM contents for persistence.
    func getRAM() -> Data {
        return Data(ram)
    }

    /// Loads RAM contents from the given data.
    func setRAM(_ data: Data) {
        for (i, byte) in data.prefix(ram.count).enumerated() {
            ram[i] = byte
        }
    }

    /// Returns the current rumble state.
    func getRumble() -> Bool {
        return rumbleEnabled
    }

    /// Sets the rumble state.
    func setRumble(_ enabled: Bool) {
        rumbleEnabled = enabled
    }

    /// Reads a byte from the cartridge at the given address.
    func read(location: UInt16) -> UInt8 {
        switch location {
        case 0x0000...0x3FFF:
            // Bank 0
            return rom[Int(location)]
        case 0x4000...0x7FFF:
            // Switchable ROM bank
            let bank = romBank == 0 ? 1 : romBank
            let offset = Int(bank) * 0x4000 + Int(location - 0x4000)
            return rom[safe: offset] ?? 0xFF
        case 0xA000...0xBFFF:
            if ramEnabled {
                let offset = Int(ramBank) * 0x2000 + Int(location - 0xA000)
                return ram[safe: offset] ?? 0xFF
            }
            return 0xFF
        default:
            return 0xFF
        }
    }

    /// Writes a byte to the cartridge at the given address.
    func write(location: UInt16, value: UInt8) {
        switch location {
        case 0x0000...0x1FFF:
            // RAM enable/disable
            ramEnabled = (value & 0x0F) == 0x0A
        case 0x2000...0x2FFF:
            // ROM bank number (lower 8 bits)
            romBank = (romBank & 0x100) | UInt16(value)
        case 0x3000...0x3FFF:
            // ROM bank number (bit 9)
            romBank = (romBank & 0xFF) | (UInt16(value & 0x01) << 8)
        case 0x4000...0x5FFF:
            // RAM bank number
            ramBank = value & 0x0F
        case 0x6000...0x7FFF:
            // Rumble control (bit 3)
            rumbleEnabled = (value & 0x08) != 0
        case 0xA000...0xBFFF:
            if ramEnabled {
                let offset = Int(ramBank) * 0x2000 + Int(location - 0xA000)
                if offset < ram.count {
                    ram[offset] = value
                }
            }
        default:
            break
        }
    }
}

