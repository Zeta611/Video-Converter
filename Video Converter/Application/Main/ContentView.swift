//
//  ContentView.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/04.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    var body: some View {
        let state = VideoConverterState()
        return VideoConverterView(
            state: state,
            actionHandler: VideoConverterInteractor(state: state)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
