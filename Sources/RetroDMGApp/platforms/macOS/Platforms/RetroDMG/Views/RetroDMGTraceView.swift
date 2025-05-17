//
//  RetroDMGTraceView.swift
//  Retro
//
//  Created by Glenn Hevey on 8/10/2024.
//

import SwiftUI
import RetroDMG

struct RetroDMGTraceView: View {
    @Environment(AppState.self) var appState: AppState
    @State var traceStack = [String](repeating: "", count: 20)
    
    @MainActor
    var currentTrace: String {
        let state = appState.activePlatform!.state as! DMGState
        return "\(state.a.displayName): \(state.a.value.hex) \(state.f.displayName): \(state.f.value.hex) \(state.b.displayName): \(state.b.value.hex) \(state.c.displayName): \(state.c.value.hex) \(state.d.displayName): \(state.d.value.hex) \(state.e.displayName): \(state.e.value.hex) \(state.h.displayName): \(state.h.value.hex) \(state.l.displayName): \(state.l.value.hex) \(state.sp.displayName): \(state.sp.value.hex) \(state.pc.displayName): \(state.pc.value.hex) (\(state.PcLoc.value) \(state.PcLoc1.value) \(state.PcLoc2.value) \(state.PcLoc3.value))"
    }
    
    var body: some View {
        Form {
            ScrollView {
                ForEach(0..<traceStack.endIndex, id: \.self) { index in
                    HStack {
                        Text(traceStack[index])
                        Spacer()
                    }
                }
                
            }
            .padding(.horizontal, 10)
        }
        .onChange(of: currentTrace, initial: true) { _, newTrace in
            traceStack.insert(newTrace, at: 0)
            traceStack.removeLast()
        }
    }
}

#Preview {
    RetroDMGTraceView()
}
