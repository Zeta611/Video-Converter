//
//  VideoConverterInteractor.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/04.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import AVFoundation
import Cocoa
import Combine
import Foundation

protocol VideoConverterActionHandler {
    func setInputVideo(at url: URL)
    func convertVideo()
}

final class VideoConverterInteractor : VideoConverterActionHandler {
    private enum PanelError : Error {
        case cancelled
    }

    let state: VideoConverterState

    private var cancellables = [AnyCancellable]()

    init(state: VideoConverterState) {
        self.state = state
    }

    func setInputVideo(at url: URL) {
        if case .inProgress = state.conversionStatus { return }
        state.conversionStatus = .undone
        state.inputVideoPath = url
        state.outputVideoPath = nil
    }

    func convertVideo() {
        guard let inputVideoPath = state.inputVideoPath else {
            assertionFailure("inputVideoPath should be set")
            return
        }
        let videoTargetFormat = state.videoTargetFormat
        let videoTargetQuality = state.videoTargetQuality

        weak var state = self.state

        openPanel(at: inputVideoPath)
            .catch { _ in Empty() }
            .setFailureType(to: VideoConversionError.self)
            .flatMap { [weak self] outputVideoPath in
                self?.getExportSession(
                    from: inputVideoPath,
                    to: outputVideoPath,
                    format: videoTargetFormat,
                    quality: videoTargetQuality
                ) ?? Result.Publisher(.unknown)
            }
            .flatMap { exportSession in
                Future<AVAssetExportSession, VideoConversionError> { promise in
                    exportSession.exportAsynchronously {
                        promise(.success(exportSession))
                    }
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    guard case let .failure(error) = completion else { return }
                    state?.conversionStatus = .failed(error)
                },
                receiveValue: { (exportSession: AVAssetExportSession) in
                    switch (exportSession.status, exportSession.error) {
                    case (.failed, .none):
                        assertionFailure("exportSession should have an error")
                        state?.conversionStatus = .failed(.unknown)

                    case (.failed, .some(let error)):
                        state?.conversionStatus = .failed(
                            .exportSessionError(error)
                        )

                    case (.cancelled, _):
                        state?.conversionStatus = .failed(.exportCancelled)

                    case (.completed, _):
                        state?.conversionStatus = .done

                    default:
                        state?.conversionStatus = .failed(.unknown)
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func openPanel(at inputVideoPath: URL) -> Future<URL, PanelError> {
        let panel = NSSavePanel()
        panel.directoryURL = inputVideoPath.deletingLastPathComponent()

        let fileName = inputVideoPath.deletingPathExtension().lastPathComponent
        let fileExtension = state.videoTargetFormat.rawValue
        panel.nameFieldStringValue = "\(fileName).\(fileExtension)"

        return Future { promise in
            panel.begin { response in
                guard
                    case .OK = response,
                    let outputVideoPath = panel.url
                else {
                    promise(.failure(.cancelled))
                    return
                }
                self.state.outputVideoPath = outputVideoPath
                self.state.conversionStatus = .inProgress(0)
                promise(.success(outputVideoPath))
            }
        }
    }

    private func getExportSession(
        from inputVideoPath: URL,
        to outputVideoPath: URL,
        format videoTargetFormat: VideoFormat,
        quality videoTargetQuality: VideoQuality
    ) -> Result<AVAssetExportSession, VideoConversionError>.Publisher {
        let avAsset = AVURLAsset(url: inputVideoPath)
        guard let exportSession = AVAssetExportSession(
            asset: avAsset,
            presetName: videoTargetQuality.avAssetExportPreset
        ) else {
            return Result.Publisher(.noExportSession)
        }

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputVideoPath.path) {
            do {
                try fileManager.removeItem(at: outputVideoPath)
            } catch {
                return Result.Publisher(.fileManagerError(error))
            }
        }

        exportSession.outputURL = outputVideoPath
        exportSession.outputFileType = videoTargetFormat.avFileType
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.timeRange = CMTimeRangeMake(
            start: CMTimeMakeWithSeconds(0, preferredTimescale: 0),
            duration: avAsset.duration
        )

        var progressCancellable: AnyCancellable?
        progressCancellable = Timer
            .publish(every: 0.1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak state] _ in
                let progress = exportSession.progress
                if progress == 1 {
                    progressCancellable?.cancel()
                } else {
                    state?.conversionStatus = .inProgress(progress)
                }
            }

        return Result.Publisher(exportSession)
    }
}
