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
    @State private var maxTextWidth: CGFloat?

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
        VStack(spacing: 15) {
            VStack(alignment: .labelTrailingAlignment) {
                HStack {
                    wrappedText("Convert to")
                    Picker(
                        selection: $state.videoTargetFormat,
                        label: Text("Convert to")
                    ) {
                        ForEach(VideoFormat.allCases, id: \.self) {
                            Text(".\($0.rawValue) (\($0.description))")
                        }
                    }
                }

                HStack {
                    wrappedText("Quality")
                    Picker(
                        selection: $state.videoTargetQuality,
                        label: Text("Quality")
                    ) {
                        ForEach(VideoQuality.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                }
            }
            .backgroundPreferenceValue(BoundsPreferenceKey.self) { values in
                GeometryReader { geometry in
                    self.readWidth(from: values, in: geometry)
                }
            }
            .labelsHidden()

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
                ) { item, _ in
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

            Button("Convert") {
                self.actionHandler.convertVideo()
            }
            .disabled(
                state.inputVideoPath == nil
                    || state.conversionStatus.isInProgress
            )
        }
        .padding()
    }

    private func wrappedText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .lineLimit(1)
            .frame(width: maxTextWidth, alignment: .trailing)
            .alignmentGuide(.labelTrailingAlignment) { $0[.trailing] }
            .anchorPreference(
                key: BoundsPreferenceKey.self,
                value: .bounds
            ) {
                [BoundsPreference(bounds: $0)]
            }
    }

    private func readWidth(
        from values: [BoundsPreference],
        in geometry: GeometryProxy
    ) -> some View {
        DispatchQueue.main.async {
            self.maxTextWidth = values
                .map { geometry[$0.bounds].width }
                .max()
        }
        return Rectangle()
            .hidden()
    }
}

extension VideoConverterView {
    private struct DropZone : View {
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
                        .fontWeight(.bold)
                    Spacer()
                    if progress != nil {
                        // swiftlint:disable:next force_unwrapping
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
    private struct StubActionHandler : VideoConverterActionHandler {
        func setInputVideo(at url: URL) {}
        func convertVideo() {}
    }

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
}
