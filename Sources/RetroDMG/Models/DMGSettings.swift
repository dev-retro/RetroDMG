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
    public var gameSetting = GameSetting()
}

public struct BiosSetting: RetroSetting {
    public var name: String = "Bios"
    public var type: RetroSettingType = .file
    public var value: [UInt8]?
}

public struct GameSetting: RetroSetting {
    public var name: String = "Game"
    public var type: RetroSettingType = .file
    public var value: [UInt8]?
}
