//
//  RetroDMGView.swift
//  Retro
//
//  Created by Glenn Hevey on 27/12/2023.
//

import SwiftUI
import RetroKit
import RetroDMG

struct RetroDMGView: View {
    @Environment(AppState.self) var appState: AppState
    @State var viewModel = RetroDMGViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            if viewModel.isLoaded {
                VStack {
                    HStack {
                        VStack {
                            HStack {
                                if let core = viewModel.core {
                                    if viewModel.debugViewShowing {   
                                        switch viewModel.debugView {
                                        case .Debug:
                                            RetroDMGDebugView(core: core)
                                        case .Tilemap9800:
                                            RetroDMGTilemap98View(core: core)
                                        case .Tilemap9C00:
                                            RetroDMGTilemap9CView(core: core)
                                        }
                                    }
                                    RetroDMGViewPort {
                                        RetroDMGMetalView(core: core)
                                    }
                                    .aspectRatio(CGSize(width: 160, height: 144), contentMode: .fit)
                                    .focusable()
                                    .focusEffectDisabled()
                                    .onKeyPress(keys: ["w", "s", "a", "d", "p", "l","c", "v"], phases: [.all]) { press in
                                            viewModel.keys = core.listInputs()
                                            switch press.key.character {
                                            case "w":
                                                for (index, key) in viewModel.keys.enumerated() {
                                                    if key.name == "Up" && press.phase == .down || key.name == "Up" && press.phase == .repeat {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = true
                                                        core.update(inputs: viewModel.keys)
                                                    } else if key.name == "Up" && press.phase == .up {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = false
                                                        core.update(inputs: viewModel.keys)
                                                    }
                                                }
                                                
                                                return .handled
                                            case "s":
                                                for (index, key) in viewModel.keys.enumerated() {
                                                    if key.name == "Down" && press.phase == .down || key.name == "Down" && press.phase == .repeat {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = true
                                                        core.update(inputs: viewModel.keys)
                                                    } else if key.name == "Down" && press.phase == .up {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = false
                                                        core.update(inputs: viewModel.keys)
                                                    }
                                                }
                                                
                                                return .handled
                                            case "a":
                                                for (index, key) in viewModel.keys.enumerated() {
                                                    if key.name == "Left" && press.phase == .down || key.name == "Left" && press.phase == .repeat {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = true
                                                        core.update(inputs: viewModel.keys)
                                                    } else if key.name == "Left" && press.phase == .up {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = false
                                                        core.update(inputs: viewModel.keys)
                                                    }
                                                }
                                                return .handled
                                            case "d":
                                                for (index, key) in viewModel.keys.enumerated() {
                                                    if key.name == "Right" && press.phase == .down || key.name == "Right" && press.phase == .repeat {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = true
                                                        core.update(inputs: viewModel.keys)
                                                    } else if key.name == "Right" && press.phase == .up {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = false
                                                        core.update(inputs: viewModel.keys)
                                                    }
                                                }
                                                return .handled
                                            case "p":
                                                for (index, key) in viewModel.keys.enumerated() {
                                                    if key.name == "A" && press.phase == .down || key.name == "A" && press.phase == .repeat {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = true
                                                        core.update(inputs: viewModel.keys)
                                                    } else if key.name == "A" && press.phase == .up {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = false
                                                        core.update(inputs: viewModel.keys)
                                                    }
                                                }
                                                return .handled
                                            case "l":
                                                for (index, key) in viewModel.keys.enumerated() {
                                                    if key.name == "B" && press.phase == .down || key.name == "B" && press.phase == .repeat {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = true
                                                        core.update(inputs: viewModel.keys)
                                                    } else if key.name == "B" && press.phase == .up {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = false
                                                        core.update(inputs: viewModel.keys)
                                                    }
                                                }
                                                return .handled
                                            case "c":
                                                for (index, key) in viewModel.keys.enumerated() {
                                                    if key.name == "Select" && press.phase == .down || key.name == "Select" && press.phase == .repeat {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = true
                                                        core.update(inputs: viewModel.keys)
                                                    } else if key.name == "Select" && press.phase == .up {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = false
                                                        core.update(inputs: viewModel.keys)
                                                    }
                                                }
                                                return .handled
                                            case "v":
                                                for (index, key) in viewModel.keys.enumerated() {
                                                    if key.name == "Start" && press.phase == .down || key.name == "Start" && press.phase == .repeat {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = true
                                                        core.update(inputs: viewModel.keys)
                                                    } else if key.name == "Start" && press.phase == .up {
                                                        viewModel.keys[index].updated = true
                                                        viewModel.keys[index].active = false
                                                        core.update(inputs: viewModel.keys)
                                                    }
                                                }
                                                return .handled
                                            default:
                                                return .ignored
                                            }
                                    }
                                } else {
                                    Text("Loading")
                                }
                            }
                        }
                        if viewModel.stateViewShowing {
                            appState.activePlatform!.stateView
                            Spacer()
                        }
                    }
                    if viewModel.traceViewShowing {
                        appState.activePlatform!.traceView
                            .frame(maxHeight: 100)
                    }
                }
            }
        }
        .toolbar(content: {
            if viewModel.debugViewShowing {
                Picker("Debug View", selection: $viewModel.debugView) {
                    Text("Tile Data").tag(RetroDMGDebugViewEnum.Debug)
                    Text("Tilemap 9800").tag(RetroDMGDebugViewEnum.Tilemap9800)
                    Text("Tilemap 9C00").tag(RetroDMGDebugViewEnum.Tilemap9C00)
                }
                .pickerStyle(.segmented)
                .disabled(!viewModel.isLoaded)
            }
            Button("Play", systemImage: "play") {
                viewModel.play()
            }
            .disabled(!viewModel.isLoaded)
            Button("Pause", systemImage: "pause") {
                viewModel.pause()
            }
            .disabled(!viewModel.isLoaded)
            Button("Stop", systemImage: "stop") {
                viewModel.stop()
                viewModel.isLoaded = false
                self.presentationMode.wrappedValue.dismiss()
            }
            .disabled(!viewModel.isLoaded)
            Button("sidebarLeft", systemImage: "inset.filled.leftthird.rectangle") {
                withAnimation {
                    viewModel.debugViewShowing.toggle()
                }
            }
            .disabled(!viewModel.isLoaded)
            Button("trace", systemImage: "inset.filled.bottomthird.rectangle") {
                withAnimation {
                    viewModel.traceViewShowing.toggle()
                }
            }
            .disabled(!viewModel.isLoaded)
            Button("sidebarRight", systemImage: "inset.filled.rightthird.rectangle") {
                withAnimation {
                    viewModel.stateViewShowing.toggle()
                }
            }
            .disabled(!viewModel.isLoaded)
        })
        .onAppear {
            if !viewModel.isLoaded {
                viewModel.isPicking.toggle()
            }
            viewModel.core = appState.activePlatform!.library as? RetroDMG
        }
        .fileImporter(
            isPresented: $viewModel.isPicking,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false,
            onCompletion: { result in
                switch result {
                case .success(let files):
                    viewModel.update(game: filePicked(path: files[0]))
                    viewModel.loadGame()
                    viewModel.isLoaded = true
                case .failure(let error):
                    print(error)
                }
            }
        )

    }
    
    
    func filePicked(path: URL) -> [UInt8] {
        var bytes = [UInt8]()
        do {
            let accessGranted = path.startAccessingSecurityScopedResource()
            if accessGranted {
                let data = try Data(contentsOf: path)
                data.withUnsafeBytes { buffer in
                    for byte in buffer {
                        bytes.append(byte)
                    }
                }
                path.stopAccessingSecurityScopedResource()
            }
        } catch {
            print(error)
        }
        return bytes
    }
}

#Preview {
    RetroDMGView()
}
