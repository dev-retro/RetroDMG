//
//  PlatformView.swift
//  Retro
//
//  Created by Glenn Hevey on 9/2/2024.
//
 
import SwiftUI
import Foundation

struct PlatformView: View {
    @Environment(AppState.self) var appState: AppState
    @State var viewModel = PlatformViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                
                if appState.activePlatform != nil {
                    Text(appState.activePlatform?.library.platformName ?? "platform name")
                    Text(appState.activePlatform?.library.platformDescription ?? "platform description")
                    Text(appState.activePlatform?.library.name ?? "name")
                    Text(appState.activePlatform?.library.description ?? "description")
                    HStack {
                        NavigationLink("Load Game") {
                            HStack {
                                appState.activePlatform!.viewPort.onAppear {
                                    appState.activePlatform?.updateLibrary()
                                }
                            }
                        }
                        
                        NavigationLink("Open Settings") {
                            withAnimation {
                                appState.activePlatform!.settingsView
                            }
                        }
                    }
                } else {
                    Text("Pick Platform")
                }
            }
        }
        .onAppear {
            viewModel.setup(appState: self.appState)
            
        }
        .navigationTitle("Retro - \(appState.activePlatform?.library.platformName ?? "Not active")")
    }
    
    
}

#Preview {
    PlatformView()
}
