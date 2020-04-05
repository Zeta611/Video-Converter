//
//  VideoConversionError.swift
//  Video Converter
//
//  Created by Jay Lee on 2020/04/06.
//  Copyright © 2020 Jay Lee. All rights reserved.
//

import Foundation

enum VideoConversionError : Error {
    case noExportSession
    case fileManagerError(Error)
    case exportCancelled
    case exportSessionError(Error)
    case unknown
}
