//
//  Global.swift
//
//
//  Created by Glenn Hevey on 12/1/2024.
//

extension UInt8 {
    func get(bit: UInt8) -> Bool {
        let value = (self >> bit) & 1
        
        return value != 0
    }
    
    mutating func set(bit: UInt8, value: Bool) {
        let mask = UInt8(1 << bit)
        
        if value {
            self != mask
        } else {
            self &= mask ^ 0xFF
        }
    }
}
