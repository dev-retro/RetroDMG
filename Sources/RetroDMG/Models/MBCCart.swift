//
//  File.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 23/11/2024.
//

import Foundation
import CryptoKit

protocol MBCCart {
    func read(location: UInt16) -> UInt8
    func write(location: UInt16, value: UInt8)
    func getRAM() -> Data?
    func setRAM(_ data: Data)
    init(data: [UInt8])
}

extension MBCCart {
    /// Returns the cartridge title from the ROM header (0x134–0x143)
    var cartridgeTitle: String {
        let romData: [UInt8]
        if let self = self as? MBC1Cart {
            romData = self.data
        } else if let self = self as? MBC2Cart {
            romData = self.rom
        } else if let self = self as? MBC3Cart {
            romData = self.rom
        } else if let self = self as? MBC5Cart {
            romData = self.rom
        } else if let self = self as? NoMBC {
            romData = self.data
        } else {
            return "Unknown"
        }
        guard romData.count > 0x143 else { return "Unknown" }
        let titleBytes = romData[0x134...0x143]
        return String(bytes: titleBytes, encoding: .ascii)?.trimmingCharacters(in: .controlCharacters.union(.whitespaces)) ?? "Unknown"
    }

    /// Returns the cartridge type from the ROM header (0x147)
    var cartridgeType: UInt8 {
        let romData: [UInt8]
        if let self = self as? MBC1Cart {
            romData = self.data
        } else if let self = self as? MBC2Cart {
            romData = self.rom
        } else if let self = self as? MBC3Cart {
            romData = self.rom
        } else if let self = self as? MBC5Cart {
            romData = self.rom
        } else if let self = self as? NoMBC {
            romData = self.data
        } else {
            return 0xFF
        }
        guard romData.count > 0x147 else { return 0xFF }
        return romData[0x147]
    }

    /// Returns a SHA-1 hash of the ROM data
    var romHash: String {
        let romData: [UInt8]
        if let self = self as? MBC1Cart {
            romData = self.data
        } else if let self = self as? MBC2Cart {
            romData = self.rom
        } else if let self = self as? MBC3Cart {
            romData = self.rom
        } else if let self = self as? MBC5Cart {
            romData = self.rom
        } else if let self = self as? NoMBC {
            romData = self.data
        } else {
            return "Unknown"
        }
        if #available(macOS 10.15, *) {
            let hash = Insecure.SHA1.hash(data: Data(romData))
            return hash.map { String(format: "%02x", $0) }.joined()
        } else {
            return "Unavailable"
        }
    }
}
