//
//  HorizontalAlignment+labelTrailingAlignment.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/12.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import SwiftUI

extension HorizontalAlignment {
    private enum LabelTrailingAlignment : AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            // Does not matter
            context[.trailing]
        }
    }

    static let labelTrailingAlignment = HorizontalAlignment(
        LabelTrailingAlignment.self
    )
}
