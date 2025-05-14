//
//  AppState.swift
//  Retro
//
//  Created by Glenn Hevey on 10/2/2024.
//

import Foundation
import RetroKit

@Observable
class AppState {
    var activePlatform: Platform?
    var platforms = [any Platform]()
    
    func addPlatform(_ platform: any Platform) {
        platforms.append(platform)
    }
}
