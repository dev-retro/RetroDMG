//
//  DMGSettings.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 13/9/2024.
//

import Foundation
import RetroSwift

public struct DMGSettings: Codable {
    public var biosSetting = BiosSetting()
}

public struct BiosSetting: RetroSetting {
    public var name: String = "Bios"
    public var type: RetroSettingType = .file
    public var value: [UInt8]?
}
