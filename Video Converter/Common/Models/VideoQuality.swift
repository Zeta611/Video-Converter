//
//  VideoQuality.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/07.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import AVFoundation
import Foundation

enum VideoQuality : String, CaseIterable {
    case original
    case q2160p = "2160p (4K)"
    case q1080p = "1080p"
    case q720p = "720p"
    case q540p = "540p"
    case q480p = "480p"

    var avAssetExportPreset: String {
        switch self {
        case .original:
            return AVAssetExportPresetPassthrough

        case .q2160p:
            return AVAssetExportPreset3840x2160

        case .q1080p:
            return AVAssetExportPreset1920x1080

        case .q720p:
            return AVAssetExportPreset1280x720

        case .q540p:
            return AVAssetExportPreset960x540

        case .q480p:
            return AVAssetExportPreset640x480
        }
    }
}
