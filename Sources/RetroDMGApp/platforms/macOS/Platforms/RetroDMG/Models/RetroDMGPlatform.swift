//
//  RetroDMGPlatform.swift
//  Retro
//
//  Created by Glenn Hevey on 29/9/2024.
//

import Foundation
import RetroDMG
import RetroKit
import SwiftUI

@MainActor
class RetroDMGPlatform: Platform {
    var library: RetroPlatform = RetroDMG()
    var settings: RetroSettings
    var state: RetroState
    var settingsView: AnyView
    var viewPort: AnyView
    var stateView: AnyView
    var traceView: AnyView
    var debugViewPort: AnyView
    
    
    init() {
        library = RetroDMG()
        settings = DMGSettings()
        state = library.debugState as! DMGState
        settingsView = AnyView(RetroDMGSettingsView(settings: settings as! DMGSettings))
        viewPort = AnyView(RetroDMGView())
        stateView = AnyView(RetroDMGStateView())
        traceView = AnyView(RetroDMGTraceView())
        debugViewPort = AnyView(RetroDMGView())
    }
    
    public func updateLibrary() {
        library.update(settings: settings)
    }
    
    public func getState() {
        state = library.debugState as! DMGState
    }
}
