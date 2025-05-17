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
                    Text("\(state.a.displayName): \(state.a.value.hex)")
                    Text("\(state.b.displayName): \(state.b.value.hex)")
                    Text("\(state.c.displayName): \(state.c.value.hex)")
                    Text("\(state.d.displayName): \(state.d.value.hex)")
                    Text("\(state.e.displayName): \(state.e.value.hex)")
                    Text("\(state.f.displayName): \(state.f.value.hex)")
                    Text("\(state.h.displayName): \(state.h.value.hex)")
                    Text("\(state.l.displayName): \(state.l.value.hex)")
                    Text("\(state.pc.displayName): \(state.pc.value.hex)")
                    Text("\(state.sp.displayName): \(state.sp.value.hex)")
                    Text("\(state.ime.displayName): \(state.ime.value)")
                } header: {
                    Text("Registers")
                        .font(.headline)
                }
                
                Section {
                    Text("\(state.JoyP.displayName): \(state.JoyP.value.hex)")
                    Text("\(state.InputB.displayName): \(state.InputB.value)")
                    Text("\(state.InputA.displayName): \(state.InputA.value)")
                    Text("\(state.InputSelect.displayName): \(state.InputSelect.value)")
                    Text("\(state.InputStart.displayName): \(state.InputStart.value)")
                    Text("\(state.InputRight.displayName): \(state.InputRight.value)")
                    Text("\(state.InputLeft.displayName): \(state.InputLeft.value)")
                    Text("\(state.InputUp.displayName): \(state.InputUp.value)")
                    Text("\(state.InputDown.displayName): \(state.InputDown.value)")
                    Text("\(state.InputButtons.displayName): \(state.InputButtons.value)")
                    Text("\(state.InputDPad.displayName): \(state.InputDPad.value)")
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
