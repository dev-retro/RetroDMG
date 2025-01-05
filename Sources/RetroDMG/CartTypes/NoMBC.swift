//
//  NoMBC.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 24/11/2024.
//

import Foundation

class NoMBC: MBCCart {
    var data: [UInt8]
    
    required init(data: [UInt8]) {
        self.data = data
    }
    
    func read(location: UInt16) -> UInt8 {
        return data[Int(location)]
    }
    
    func write(location: UInt16, value: UInt8) {
        if location >= 0x0000 && location <= 0x3FFF {
            return
        }
        data[Int(location)] = value
    }
}
