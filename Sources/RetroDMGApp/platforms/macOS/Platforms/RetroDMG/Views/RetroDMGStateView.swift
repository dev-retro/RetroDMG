//
//  RetroDMGStateView.swift
//  Retro
//
//  Created by Glenn Hevey on 6/10/2024.
//

import SwiftUI
import RetroDMG

@MainActor
struct RetroDMGStateView: View {
    @Environment(AppState.self) var appState: AppState
    var body: some View {
        Form {
            if let state = appState.activePlatform!.state as? DMGState {
                Section {
                    Text(LocalizedStringResource("\(state.a.displayName): \(String(describing: state.a.value.hex))"))
                    Text(LocalizedStringResource("\(state.b.displayName): \(String(describing: state.b.value.hex))"))
                    Text(LocalizedStringResource("\(state.c.displayName): \(String(describing: state.c.value.hex))"))
                    Text(LocalizedStringResource("\(state.d.displayName): \(String(describing: state.d.value.hex))"))
                    Text(LocalizedStringResource("\(state.e.displayName): \(String(describing: state.e.value.hex))"))
                    Text(LocalizedStringResource("\(state.f.displayName): \(String(describing: state.f.value.hex))"))
                    Text(LocalizedStringResource("\(state.h.displayName): \(String(describing: state.h.value.hex))"))
                    Text(LocalizedStringResource("\(state.l.displayName): \(String(describing: state.l.value.hex))"))
                    Text(LocalizedStringResource("\(state.pc.displayName): \(String(describing: state.pc.value.hex))"))
                    Text(LocalizedStringResource("\(state.sp.displayName): \(String(describing: state.sp.value.hex))"))
                    Text(LocalizedStringResource("\(state.ime.displayName): \(String(describing: state.ime.value))"))
                } header: {
                    Text("Registers")
                        .font(.headline)
                }
                
                Section {
                    Text(LocalizedStringResource("\(state.JoyP.displayName): \(String(describing: state.JoyP.value.hex))"))
                    Text(LocalizedStringResource("\(state.InputB.displayName): \(String(describing: state.InputB.value))"))
                    Text(LocalizedStringResource("\(state.InputA.displayName): \(String(describing: state.InputA.value))"))
                    Text(LocalizedStringResource("\(state.InputSelect.displayName): \(String(describing: state.InputSelect.value))"))
                    Text(LocalizedStringResource("\(state.InputStart.displayName): \(String(describing: state.InputStart.value))"))
                    Text(LocalizedStringResource("\(state.InputRight.displayName): \(String(describing: state.InputRight.value))"))
                    Text(LocalizedStringResource("\(state.InputLeft.displayName): \(String(describing: state.InputLeft.value))"))
                    Text(LocalizedStringResource("\(state.InputUp.displayName): \(String(describing: state.InputUp.value))"))
                    Text(LocalizedStringResource("\(state.InputDown.displayName): \(String(describing: state.InputDown.value))"))
                    Text(LocalizedStringResource("\(state.InputButtons.displayName): \(String(describing: state.InputButtons.value))"))
                    Text(LocalizedStringResource("\(state.InputDPad.displayName): \(String(describing: state.InputDPad.value))"))
                } header: {
                    Text("Inputs")
                        .font(.headline)
                        .padding(.top, 10)
                }
                
            }
            Spacer()
            
            
        }
        .frame(minWidth: 175)
    }
}

#Preview {
    RetroDMGStateView()
}
