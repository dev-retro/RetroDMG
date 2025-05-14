//
//  RetroDMGViewModel.swift
//  Retro
//
//  Created by Glenn Hevey on 27/12/2023.
//

import Foundation
import RetroDMG
import RetroKit
import Observation

@MainActor
@Observable
class RetroDMGViewModel {
    var game = [UInt8]()
    var settings: DMGSettings?
    var core: RetroDMG?
    var keys: [RetroInput] = []
    var isPicking: Bool = false
    var bootromPicking: Bool = false
    var isLoaded: Bool = false
    var debugView: RetroDMGDebugViewEnum = .Debug
    
    var stateViewShowing: Bool = false
    var traceViewShowing: Bool = false
    var debugViewShowing: Bool = false
    
    func update(game: [UInt8]) {
        self.game = game
    }
    
    
    func loadGame() {
        core?.load(file: game)
    }
    
    func play() {
        _ = core?.start()
    }
    
    func pause() {
        _ = core?.pause()
    }
    
    func stop() {
        _ = core?.stop()
    }
 }

enum RetroDMGDebugViewEnum: CaseIterable, Identifiable, CustomStringConvertible {
    var description: String {
        switch self {
        case .Tilemap9800:
            return "Tilemap 9800"
        case .Tilemap9C00:
            return "Tilemap 9C00"
        case .Debug:
            return "Debug"
        }
    }
    
    var id: Self { self }
    
    case Tilemap9800
    case Tilemap9C00
    case Debug
}
