//
//  PluginRetroDMGBuilder.swift
//  
//
//  Created by Glenn Hevey on 7/2/2024.
//

import Foundation
import RetroKit

@_cdecl("createPlatform")
public func createPlatform() -> UnsafeMutableRawPointer {
    return Unmanaged.passRetained(PluginABuilder()).toOpaque()
}

final class PluginRetroDMGBuilder: Builder {

    override func build() -> RetroPlatform {
        PluginRetroDMG()
    }
}
