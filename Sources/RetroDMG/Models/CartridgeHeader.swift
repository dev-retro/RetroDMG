//
//  File.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 21/11/2024.
//

import Foundation

struct CartridgeHeader {
    var Title: String
    var CartridgeType: UInt8
    var ROMSize: UInt8
    var RAMSize: UInt8
}

enum CartridgeType {
case ROMOnly
}
