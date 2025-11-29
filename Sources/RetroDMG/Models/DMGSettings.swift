//
//  DMGSettings.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 13/9/2024.
//

import Foundation
import RetroKit

public struct RetroDMGSettings: RetroSettings {
    public var biosSetting: DMGBiosSetting
    
    init() {
        self.biosSetting = DMGBiosSetting()
    }
}

public struct DMGBiosSetting: RetroSetting {
    public static var name: String = "RetroDMG_BiosSettings"
    public var displayName: String = "BIOS Path"
    public var type: RetroSettingType = .file
    public var displayValue: String?
    public var value: [UInt8]?
}
