//
//  File.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 23/11/2024.
//

import Foundation

protocol MBCCart {
    func read(location: UInt16) -> UInt8
    func write(location: UInt16, value: UInt8)
    
    init(data: [UInt8])
}
