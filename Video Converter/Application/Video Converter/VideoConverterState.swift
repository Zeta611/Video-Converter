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

    deinit {
        print("State released")
    }
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

    enum VideoConversionError : Error {
        case noExportSession
        case noDirectory
        case fileManagerError(Error)
        case exportFailed
        case exportCancelled
        case exportSessionError(Error)
        case unknown
    }
}
