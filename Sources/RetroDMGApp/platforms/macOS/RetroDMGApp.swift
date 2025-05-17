//
//  RetroDMGApp.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 14/5/2025.
//

#if os(macOS)
import Foundation
import SwiftUI

@main
struct RetroDMGApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            PlatformView()
        }
        .environment(appState)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button("Open") {
                    print("open")
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            CommandMenu("Platforms") {
                ForEach(appState.platforms.indices, id: \.self) { index in
                    if appState.activePlatform?.library.platformName == appState.platforms[index].library.platformName {
                        Button {
                            appState.activePlatform = nil
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                Text(appState.platforms[index].library.name)
                            }
                        }
                    } else {
                        Button(appState.platforms[index].library.name) {
                            appState.activePlatform = appState.platforms[index]
                        }
                    }
                }
            }
        }
    }
}

struct HelloView: View {
    var body: some View {
        Text("Hello world!!!!!")
    }
}
#endif
