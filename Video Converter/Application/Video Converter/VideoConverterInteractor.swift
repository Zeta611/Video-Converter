//
//  VideoConverterInteractor.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/04.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import Foundation
import Cocoa
import Combine
import AVFoundation

protocol VideoConverterActionHandler {
    func setInputVideo(at url: URL)
    func convertVideo()
}

final class VideoConverterInteractor : VideoConverterActionHandler {
    let state: VideoConverterState

    private var cancellables = [AnyCancellable]()

    func setInputVideo(at url: URL) {
        if case .inProgress = state.conversionStatus { return }
        state.conversionStatus = .undone
        state.inputVideoPath = url
        state.outputVideoPath = nil
    }

    func convertVideo() {
        weak var state = self.state
        openPanel().sink(receiveCompletion: { _ in }) { [weak self] in
            guard
                let self = self,
                let state = state,
                let videoURL = state.inputVideoPath
            else {
                preconditionFailure("inputVideoPath should be set")
            }

            let avAsset = AVURLAsset(url: videoURL, options: nil)

            guard let exportSession = AVAssetExportSession(
                asset: avAsset,
                presetName: AVAssetExportPresetPassthrough
            ) else {
                state.conversionStatus = .failed(.noExportSession)
                return
            }

            let fileManager = FileManager.default
            guard let filePath = state.outputVideoPath else {
                preconditionFailure("outputVideoPath should be set")
            }

            if fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.removeItem(at: filePath)
                } catch {
                    state.conversionStatus = .failed(.fileManagerError(error))
                    return
                }
            }

            exportSession.outputURL = filePath
            exportSession.outputFileType = state.videoTargetFormat
                .avFileType
            exportSession.shouldOptimizeForNetworkUse = true

            exportSession.timeRange = CMTimeRangeMake(
                start: CMTimeMakeWithSeconds(0, preferredTimescale: 0),
                duration: avAsset.duration
            )

            let timerCancellable = Timer
                .publish(every: 0.1, on: .main, in: .default)
                .autoconnect()
                .sink { _ in
                    state.conversionStatus = .inProgress(
                        exportSession.progress
                    )
                }
            timerCancellable.store(in: &self.cancellables)

            exportSession.exportAsynchronously {
                timerCancellable.cancel()

                DispatchQueue.main.async {
                    switch exportSession.status {
                    case .failed:
                        guard let error = exportSession.error else {
                            assertionFailure(
                                "exportSession should have an error"
                            )
                            state.conversionStatus = .failed(.unknown)
                            return
                        }
                        state.conversionStatus = .failed(
                            .exportSessionError(error)
                        )
                        return

                    case .cancelled:
                        state.conversionStatus = .failed(.exportCancelled)
                        return

                    case .completed:
                        switch exportSession.outputURL {
                        case .none:
                            assertionFailure(
                                "exportSession should have an output url"
                            )
                            state.conversionStatus = .failed(.unknown)
                            return

                        case .some:
                            state.conversionStatus = .done
                            return
                        }

                    default:
                        assertionFailure("Unknown exportSession state")
                        state.conversionStatus = .failed(.unknown)
                        return
    //                case .unknown:
    //                case .waiting:
    //                case .exporting:
                    }

                }
            }
        }
        .store(in: &cancellables)
    }

    private func openPanel() -> Future<Void, SavePanelError> {
        let panel = NSSavePanel()
        panel.directoryURL = state.inputVideoPath?.deletingLastPathComponent()
        let fileName = state.inputVideoPath?
            .deletingPathExtension()
            .lastPathComponent
            ?? "converted"
        let fileExtension = state.videoTargetFormat.rawValue
        panel.nameFieldStringValue = "\(fileName).\(fileExtension)"

        return Future { promise in
            panel.begin { response in
                guard
                    case .OK = response,
                    let url = panel.url
                else {
                    promise(.failure(.cancelled))
                    return
                }
                self.state.outputVideoPath = url
                self.state.conversionStatus = .inProgress(0)
                promise(.success(Void()))
            }
        }
    }

    private enum SavePanelError : Error {
        case cancelled
    }

    init(state: VideoConverterState) {
        self.state = state
    }

    deinit {
        print("Interactor released")
    }
}

extension Notification.Name {
    static let progressBarPercentage = Self("ProgressBarPercentage")
}
