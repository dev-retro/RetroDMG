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
            cart = MBC1Cart(data: rom, RAMSize: ramSize!, ROMSize: romSize!)
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
}


enum MBCError: Error {
    case MBCTypeError(String)
    case MBCNotLoaded
}
