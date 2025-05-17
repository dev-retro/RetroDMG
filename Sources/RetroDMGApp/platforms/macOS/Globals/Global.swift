//
//  Global.swift
//  Retro
//
//  Created by Glenn Hevey on 27/12/2023.
//
import Foundation

extension UInt8 {
    var hex: String {
        String(format:"%02X", self)
    }
}

extension UInt16 {
    var hex: String {
        String(format:"%04X", self)
    }
}


struct Vertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
}
