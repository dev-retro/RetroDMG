//
//  Platform.swift
//  Retro
//
//  Created by Glenn Hevey on 12/11/2023.
//

import Foundation
import SwiftData
import RetroKit
import SwiftUI

@MainActor
protocol Platform {
    var library: RetroPlatform { get }
    var settings: RetroSettings { get }
    var state: RetroState { get }
    var settingsView: AnyView { get }
    var viewPort: AnyView { get }
    var stateView: AnyView { get }
    var traceView: AnyView { get }
    var debugViewPort: AnyView { get }
    
    func updateLibrary()
}
