//
//  DMGSettings.swift
//  RetroDMG
//
//  Created by Glenn Hevey on 13/9/2024.
//

import Foundation
import RetroKit

public struct RetroDMGSettings: RetroSettings {
    public var items: [RetroSettingItem]
    public var biosSetting: DMGBiosSetting
    
    public init() {
        self.biosSetting = DMGBiosSetting()
        self.items = [
            RetroSettingItem(
                name: DMGBiosSetting.name,
                displayName: biosSetting.displayName,
                type: biosSetting.type,
                displayValue: biosSetting.displayValue,
                value: biosSetting.value.map { RetroSettingValue.bytes(Data($0)) }
            )
        ]
    }
    
    mutating func applyItems() {
        guard let item = items.first(where: { $0.name == DMGBiosSetting.name }) else { return }
        biosSetting.displayValue = item.displayValue
        if case .bytes(let data)? = item.value {
            biosSetting.value = Array(data)
        } else {
            biosSetting.value = nil
        }
    }
}

public struct DMGBiosSetting: RetroSetting {
    public static var name: String = "RetroDMG_BiosSettings"
    public var displayName: String = "BIOS Path"
    public var type: RetroSettingType = .file
    public var displayValue: String?
    public var value: [UInt8]?
}
