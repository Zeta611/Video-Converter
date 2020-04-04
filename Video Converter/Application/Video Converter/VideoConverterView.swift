//
//  VideoConverterView.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/04.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import SwiftUI

struct VideoConverterView : View {
    @ObservedObject var state: VideoConverterState
    var actionHandler: VideoConverterActionHandler

    @State private var cursorOnDropView = false

    private var prompt: String {
        switch state.conversionStatus {
        case .undone:
            switch state.inputVideoPath {
            case .none:
                return "Drop a video here!"

            case .some(let url):
                let path = url.absoluteString
                    .replacingOccurrences(of: "file://", with: "")
                guard let decoded = path.removingPercentEncoding else {
                    return path
                }
                return decoded
            }

        case .inProgress(let progress):
            let percentage = String(format: "%.2f", progress * 100)
            return "Converting... (\(percentage)%)"

        case .failed(let error):
            return error.localizedDescription

        case .done:
            return "Successfully converted!"
        }
    }

    private var dropZoneStrokeStyle: StrokeStyle {
        cursorOnDropView ?
            StrokeStyle(lineWidth: 3) :
            StrokeStyle(lineWidth: 3, dash: [15])
    }

    private var dropZoneStrokeColor: Color {
        cursorOnDropView ?
            Color(.selectedContentBackgroundColor) :
            Color(.selectedTextBackgroundColor)
    }

    private var dropZoneFillColor: Color {
        cursorOnDropView ? Color(.selectedTextBackgroundColor) : .clear
    }

    private var progress: Float? {
        if case let .inProgress(progress) = state.conversionStatus {
            return progress
        } else {
            return nil
        }
    }

    var body: some View {
        VStack {
            Picker(
                selection: $state.videoTargetFormat,
                label: Text("Convert to:")
            ) {
                ForEach(VideoFormat.allCases, id: \.self) {
                    Text(".\($0.rawValue) (\($0.description))")
                }
            }
            .padding([.horizontal, .top])

            DropZone(
                fillColor: dropZoneFillColor,
                strokeColor: dropZoneStrokeColor,
                strokeStyle: dropZoneStrokeStyle,
                prompt: prompt,
                progress: progress
            )
            .onDrop(
                of: [kUTTypeFileURL as String],
                isTargeted: $cursorOnDropView
            ) { itemProviders in
                guard let itemProvider = itemProviders.first
                    else { return false }

                itemProvider.loadItem(
                    forTypeIdentifier: kUTTypeFileURL as String,
                    options: nil
                ) { item, error in
                    guard
                        let data = item as? Data,
                        let url = URL(
                            dataRepresentation: data,
                            relativeTo: nil
                        )
                    else { return }
                    DispatchQueue.main.async {
                        self.actionHandler.setInputVideo(at: url)
                    }
                }
                return true
            }
            .padding()

            Button("Convert") {
                self.actionHandler.convertVideo()
            }
            .disabled(
                state.inputVideoPath == nil
                    || !state.conversionStatus.isUndone
            )
            .padding(.bottom)
        }
    }
}

extension VideoConverterView {
    struct DropZone : View {
        let fillColor: Color
        let strokeColor: Color
        let strokeStyle: StrokeStyle
        let prompt: String
        let progress: Float?

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(fillColor)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(strokeColor, style: strokeStyle)
                VStack {
                    Spacer()
                    Text(prompt)
                        .font(.largeTitle)
                    Spacer()
                    if progress != nil {
                        ProgressBar(progress: progress!)
                            .frame(height: 7)
                            .padding()
                    } else {
                        EmptyView()
                    }
                }
            }
        }
    }
}

struct VideoConverterView_Previews : PreviewProvider {
    static var previews: some View {
        let state = VideoConverterState()
        let actionHandler = StubActionHandler()
        return Group {
            VideoConverterView(state: state, actionHandler: actionHandler)
                .colorScheme(.light)
            VideoConverterView(state: state, actionHandler: actionHandler)
                .colorScheme(.dark)
        }
    }

    private struct StubActionHandler : VideoConverterActionHandler {
        func setInputVideo(at url: URL) {}
        func convertVideo() {}
    }
}
