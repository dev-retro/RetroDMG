//
//  RetroDMGSettingsView.swift
//  Retro
//
//  Created by Glenn Hevey on 5/10/2024.
//

import SwiftUI
import RetroDMG

struct RetroDMGSettingsView: View {
    var settings: DMGSettings
    @State var isPicking: Bool = false
    var body: some View {
        return Form {
            Text("RetroDMG Settings")
            HStack {
                Text("\(settings.bioSetting.displayName):")
                Text(settings.bioSetting.displayValue ?? "")
                Spacer()
                Button("Select") {
                    isPicking.toggle()
                }
                .fileImporter(
                    isPresented: $isPicking,
                    allowedContentTypes: [.data],
                    allowsMultipleSelection: false,
                    onCompletion: { result in
                        switch result {
                        case .success(let files):
                            let value = filePicked(path: files.first!)
                            settings.bioSetting.displayValue = files.first?.path(percentEncoded: false)
                            settings.bioSetting.value = value
                        case .failure(let error):
                            print(error)
                        }
                    }
                )
                
            }
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
}
