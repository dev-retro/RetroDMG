//
//  MBC.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 23/11/2024.
//

import Foundation

class MBC {
    public var cart: MBCCart?
    
    func load(rom: [UInt8]) throws {
        let type: MBCType? = MBCType(rawValue: rom[0x147])
        let romSize: ROMSize? = ROMSize(rawValue: rom[0x148])
        let ramSize: RAMSize? = RAMSize(rawValue: rom[0x149])
        
        switch type {
        case .NoMBC:
            cart = NoMBC(data: rom)
        case .MBC1, .MBC1RAM, .MBC1RAMBattery:
            guard let validRamSize = ramSize, let validRomSize = romSize else {
                throw MBCError.MBCTypeError("MBC1: ramSize or romSize is nil")
            }
            cart = MBC1Cart(data: rom, RAMSize: validRamSize, ROMSize: validRomSize)
        case .MBC2, .MBC2Battery:
            cart = MBC2Cart(data: rom)
        case .MBC3, .MBC3RAM, .MBC3RAMBattery, .MBC3TimerBattery, .MBC3TimerRAMBattery:
            let ramBytes = ramSize != nil ? Int(ramSize!.bankCount) * 0x2000 : 0
            cart = MBC3Cart(rom: rom, ramSize: ramBytes)
        case .MBC5, .MBC5RAM, .MBC5RAMBattery, .MBC5Rumble, .MBC5RumbleRAM, .MBC5RumbleRAMBattery:
            let ramBytes = ramSize != nil ? Int(ramSize!.bankCount) * 0x2000 : 0
            cart = MBC5Cart(rom: rom, ramSize: ramBytes)
        case .none:
            throw MBCError.MBCTypeError("MBC Type not found: (\(rom[0x147]))")
        }
    }
    
    func write(location: UInt16, value: UInt8) throws {
        guard let cart = cart else {
            throw MBCError.MBCNotLoaded
        }
        
        cart.write(location: location, value: value)
    }
    
    func read(location: UInt16) throws -> UInt8 {
        guard let cart = cart else {
            throw MBCError.MBCNotLoaded
        }
        
        return cart.read(location: location)
    }
    
    var currentROMBank: UInt8 {
        if let mbc3Cart = cart as? MBC3Cart {
            return mbc3Cart.romBank
        }
        return 1 // Default to bank 1 if unknown
    }
}


enum MBCError: Error {
    case MBCTypeError(String)
    case MBCNotLoaded
}
