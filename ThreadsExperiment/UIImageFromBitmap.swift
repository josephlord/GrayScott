//
//  UIImageFromBitmap.swift
//  ThreadsExperiment
//
//  Created by Joseph on 22/08/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import UIKit

private let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
private let bitmapInfo:CGBitmapInfo = CGBitmapInfo(CGImageAlphaInfo.NoneSkipFirst.toRaw())

func imageFromARGB32Bitmap(pixels:ImageBitmap, width:UInt, height:UInt)->UIImage {
    let bitsPerComponent:UInt = 8
    let bitsPerPixel:UInt = 32
    
    assert(pixels.data.count == Int(width * height))
    
    var data = pixels.data // Copy to mutable []
    let providerRef = CGDataProviderCreateWithCFData(
        NSData(bytes: &data, length: data.count * sizeof(PixelData))
    )
    
    let cgim = CGImageCreate(
        width,
        height,
        bitsPerComponent,
        bitsPerPixel,
        width * UInt(sizeof(PixelData)),
        rgbColorSpace,
        bitmapInfo,
        providerRef,
        nil,
        true,
        kCGRenderingIntentDefault
    )
    return UIImage(CGImage: cgim)
}