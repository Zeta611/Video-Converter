//
//  VideoFormat.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/04.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import AVFoundation
import Foundation

enum VideoFormat : String, CustomStringConvertible, CaseIterable, Hashable {
    case mov
    case mp4
    case m4v

    var description: String {
        switch self {
        case .mov: return "QuickTime"
        case .mp4: return "MPEG-4"
        case .m4v: return "M4V"
        }
    }

    var avFileType: AVFileType {
        switch self {
        case .mov: return .mov
        case .mp4: return .mp4
        case .m4v: return .m4v
        }
    }
}
