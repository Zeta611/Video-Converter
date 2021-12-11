//
//  ProgressBar.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/05.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import SwiftUI

struct ProgressBar : View {
    let progress: Float

    var body: some View {
        GeometryReader { geometryReader in
            Capsule()
                .foregroundColor(
                    Color(.unemphasizedSelectedContentBackgroundColor)
            )
            Capsule()
                .frame(width: geometryReader.size.width * self.progress.cg)
                .foregroundColor(.green)
                .animation(.easeIn, value: progress)
        }
    }
}

struct ProgressBar_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            ProgressBar(progress: 0.6).colorScheme(.light)
            ProgressBar(progress: 0.6).colorScheme(.dark)
        }
    }
}
