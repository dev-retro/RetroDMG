//
/// Supported Memory Bank Controller (MBC) types for Game Boy cartridges.
///
/// - NoMBC: No memory bank controller (ROM only)
/// - MBC1: MBC1 controller
/// - MBC1RAM: MBC1 with RAM
/// - MBC1RAMBattery: MBC1 with RAM and battery
/// - MBC2: MBC2 controller (internal 4-bit RAM)
/// - MBC2Battery: MBC2 with battery
/// - MBC3TimerBattery: MBC3 with RTC and battery
/// - MBC3TimerRAMBattery: MBC3 with RTC, RAM, and battery
/// - MBC3: MBC3 controller
/// - MBC3RAM: MBC3 with RAM
/// - MBC3RAMBattery: MBC3 with RAM and battery
/// - MBC5: MBC5 controller
/// - MBC5RAM: MBC5 with RAM
/// - MBC5RAMBattery: MBC5 with RAM and battery
/// - MBC5Rumble: MBC5 with rumble
/// - MBC5RumbleRAM: MBC5 with rumble and RAM
/// - MBC5RumbleRAMBattery: MBC5 with rumble, RAM, and battery
public enum MBCType: UInt8 {
    case NoMBC = 0x00
    case MBC1 = 0x01
    case MBC1RAM = 0x02
    case MBC1RAMBattery = 0x03
    case MBC2 = 0x05
    case MBC2Battery = 0x06
    case MBC3TimerBattery = 0x0F
    case MBC3TimerRAMBattery = 0x10
    case MBC3 = 0x11
    case MBC3RAM = 0x12
    case MBC3RAMBattery = 0x13
    case MBC5 = 0x19
    case MBC5RAM = 0x1A
    case MBC5RAMBattery = 0x1B
    case MBC5Rumble = 0x1C
    case MBC5RumbleRAM = 0x1D
    case MBC5RumbleRAMBattery = 0x1E
}

public enum ROMSize: UInt8 {
    case _32KB = 0x00
    case _64KB = 0x01
    case _128KB = 0x02
    case _256KB = 0x03
    case _512KB = 0x04
    case _1MB = 0x05
    case _2MB = 0x06
    case _4MB = 0x07
    case _8MB = 0x08
    
    var bankCount: UInt16 {
        switch self {
        case ._32KB:
            return 2
        case ._64KB:
            return 4
        case ._128KB:
            return 8
        case ._256KB:
            return 16
        case ._512KB:
            return 32
        case ._1MB:
            return 64
        case ._2MB:
            return 128
        case ._4MB:
            return 256
        case ._8MB:
            return 512
        }
    }
}

public enum RAMSize: UInt8 {
    case None = 0x00
    case _8KB = 0x02
    case _32KB = 0x03
    case _128KB = 0x04
    case _64KB = 0x05
    
    var bankCount: UInt8 {
        switch self {
        case .None:
            return 0
        case ._8KB:
            return 1
        case ._32KB:
            return 4
        case ._128KB:
            return 16
        case ._64KB:
            return 8
        }
    }
}


