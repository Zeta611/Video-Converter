//
//  BoundsPreferenceKey.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/12.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import SwiftUI

struct BoundsPreferenceKey: PreferenceKey {
    static var defaultValue = [BoundsPreference]()

    static func reduce(
        value: inout [BoundsPreference],
        nextValue: () -> [BoundsPreference]
    ) {
        value.append(contentsOf: nextValue())
    }
}
