//
//  File.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 21/11/2024.
//

import Foundation

/// CartridgeHeader describes the metadata for a Game Boy cartridge.
///
/// - Title: The title of the game.
/// - CartridgeType: The raw cartridge type byte (used to determine MBC type).
/// - ROMSize: The raw ROM size byte.
/// - RAMSize: The raw RAM size byte.
/// - mbcType: The parsed MBC type (if recognized).
/// - isMBC2: True if this is an MBC2 or MBC2Battery cartridge.
struct CartridgeHeader {
    /// The title of the game.
    var Title: String
    /// The raw cartridge type byte.
    var CartridgeType: UInt8
    /// The raw ROM size byte.
    var ROMSize: UInt8
    /// The raw RAM size byte.
    var RAMSize: UInt8

    /// Returns the MBC type for this cartridge, if recognized.
    var mbcType: MBCType? {
        return MBCType(rawValue: CartridgeType)
    }

    /// Returns true if this is an MBC2 or MBC2Battery cartridge.
    var isMBC2: Bool {
        return CartridgeType == MBCType.MBC2.rawValue || CartridgeType == MBCType.MBC2Battery.rawValue
    }
}

enum CartridgeType {
case ROMOnly
}
