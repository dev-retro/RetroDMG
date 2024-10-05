//
//  DMGSettings.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 13/9/2024.
//

import Foundation
import RetroSwift

public class DMGSettings: RetroSettings {
    public var bioSetting: DMGBiosSetting
    
    public init(bioSetting: DMGBiosSetting = DMGBiosSetting(name: "bios", displayName: "BIOS Path", type: .file, value: nil, displayValue: nil)) {
        self.bioSetting = bioSetting
    }
}

public struct DMGBiosSetting: RetroSetting {
    public var name: String
    public var displayName: String
    public var displayValue: String?
    public var type: RetroSettingType
    public var value: [UInt8]?
    
    public init(name: String, displayName: String, type: RetroSettingType, value: [UInt8]?, displayValue: String?) {
        self.name = name
        self.displayName = displayName
        self.type = type
        self.value = value
        self.displayValue = displayValue
    }
}
