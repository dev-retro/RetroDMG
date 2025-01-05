//
//  MBCType.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 23/11/2024.
//

import Foundation

public enum MBCType: UInt8 {
    case NoMBC = 0x00 // No MBC
    case MBC1 = 0x01 // MBC1
    case MBC1RAM = 0x02
    case MBC1RAMBattery = 0x03
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
    case _1_1MB = 0x52
    case _1_2MB = 0x53
    case _1_5MB = 0x54
    
    var bankCount: Int {
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
        case ._1_1MB:
            return 72
        case ._1_2MB:
            return 80
        case ._1_5MB:
            return 96
        }
    }
}

public enum RAMSize: UInt8 {
    case None = 0x00
    case _8KB = 0x02
    case _32KB = 0x03
    case _128KB = 0x04
    case _64KB = 0x05
    
    var bankCount: Int {
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


