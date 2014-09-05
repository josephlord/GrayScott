//
//  GrayScottRenderer.swift
//  ThreadsExperiment
//
//  Created by Simon Gladman on 03/08/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import Foundation

public struct PixelData {
    var a:UInt8 = 0
    var r:UInt8
    var g:UInt8
    var b:UInt8
}

public struct ImageBitmap {
    var data: [Int8]
    init() {
        data = [Int8](count: 4 * Constants.LENGTH_SQUARED, repeatedValue: -1)
    }
}
