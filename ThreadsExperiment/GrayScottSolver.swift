//
//  GrayScottSolver.swift
//  ThreadsExperiment
//
//  Created by Simon Gladman on 02/08/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//
// Thanks to: http://tetontech.wordpress.com/2014/06/03/swift-ios-and-threading/
//
//  Karlm Sims on Gray Scott: http://www.karlsims.com/rd.html
//  My work with reaction diffusion: http://flexmonkey.blogspot.co.uk/search/label/Reaction%E2%80%93diffusion
//

import Foundation
import UIKit

struct GrayScottParmeters {
    var f : Double
    var k : Double
    var dU : Double
    var dV : Double
}

public class GrayScottData {
    private var gsData:[GrayScottStruct]
    init() {
        gsData = [GrayScottStruct]()
        for i in 0..<(Constants.LENGTH * Constants.LENGTH) {
            gsData.append(GrayScottStruct(u: 0, v: 0))
        }
    }
    init(data:[GrayScottStruct]){
        gsData = data
    }
    
    subscript(index: Int) -> GrayScottStruct {
        get {
            return gsData[index]
        }
        set(newValue) {
            gsData[index] = newValue
        }
    }
    func dup()->GrayScottData {
        return GrayScottData(data: gsData)
    }
}


func grayScottSolver(grayScottConstData: GrayScottData, parameters:GrayScottParmeters, outputData:GrayScottData) {
    let startTime : CFAbsoluteTime = CFAbsoluteTimeGetCurrent();
    
    var index : Int = 0;
    for i in 0 ..< Constants.LENGTH
    {
        for j in 0 ..< Constants.LENGTH
        {
            let thisPixel = grayScottConstData[i * Constants.LENGTH + j]
            let northPixel = grayScottConstData[i * Constants.LENGTH + (j + 1).wrap(Constants.LENGTH_MINUS_ONE)]
            let southPixel = grayScottConstData[i * Constants.LENGTH + (j - 1).wrap(Constants.LENGTH_MINUS_ONE)]
            let eastPixel = grayScottConstData[(i - 1).wrap(Constants.LENGTH_MINUS_ONE) * Constants.LENGTH + j]
            let westPixel = grayScottConstData[(i + 1).wrap(Constants.LENGTH_MINUS_ONE) * Constants.LENGTH + j]
            
            let laplacianU = northPixel.u + southPixel.u + westPixel.u + eastPixel.u - (4.0 * thisPixel.u);
            let laplacianV = northPixel.v + southPixel.v + westPixel.v + eastPixel.v - (4.0 * thisPixel.v);
            let reactionRate = thisPixel.u * thisPixel.v * thisPixel.v;
            
            let deltaU : Double = parameters.dU * laplacianU - reactionRate + parameters.f * (1.0 - thisPixel.u);
            let deltaV : Double = parameters.dV * laplacianV + reactionRate - parameters.k * thisPixel.v;
            
            outputData[index].u = (thisPixel.u + deltaU).clip()
            outputData[index].v = (thisPixel.v + deltaV).clip()
            ++index
            //let outputPixel = GrayScottStruct(u: (thisPixel.u + deltaU).clip(), v: (thisPixel.v + deltaV).clip())
            
            //outputArray.append(outputPixel)
            
            //outputData[index++] = outputPixel;
        }
    }

    
    println("S  SOLVER:" + NSString(format: "%.4f", CFAbsoluteTimeGetCurrent() - startTime));
}
