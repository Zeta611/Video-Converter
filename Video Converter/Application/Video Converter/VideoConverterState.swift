//
//  VideoConverterState.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/04.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import Foundation

final class VideoConverterState : ObservableObject {
    @Published var inputVideoPath: URL?
    @Published var outputVideoPath: URL?
    @Published var conversionStatus: VideoConversionStatus = .undone
    @Published var videoTargetFormat: VideoFormat = .mov
    @Published var videoTargetQuality: VideoQuality = .original
}

extension VideoConverterState {
    enum VideoConversionStatus {
        case undone
        case inProgress(Float)
        case done
        case failed(VideoConversionError)

        var isUndone: Bool {
            if case .undone = self { return true } else { return false }
        }

        var isInProgress: Bool {
            if case .inProgress = self { return true } else { return false }
        }
    }
}
