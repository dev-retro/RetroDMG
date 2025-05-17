//
//  PlatformViewModel.swift
//  Retro
//
//  Created by Glenn Hevey on 9/2/2024.
//

import Foundation
import RetroKit
import RetroDMG

///Platform imports
//import RetroC8
import RetroDMG

@MainActor
@Observable
class PlatformViewModel {
    var appState: AppState?
    
    func setup(appState: AppState) {
        self.appState = appState
        
        self.appState!.platforms.append(RetroDMGPlatform())
//        self.appState!.platforms.append(RetroC8())
        
        self.appState!.activePlatform = self.appState!.platforms.first
    }
 
    func getPlatforms() -> [any Platform] {
        return self.appState?.platforms ?? [any Platform]()
    }
}
