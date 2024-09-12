//
//  File.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 12/9/2024.
//

import Foundation


extension UInt8 {
    var hex: String {
        String(format:"%02X", self)
    }
    
    init(_ boolean: Bool) {
         
        self = boolean ? 1 : 0
    }
}

extension UInt16 {
    var hex: String {
        String(format:"%04X", self)
    }
}
