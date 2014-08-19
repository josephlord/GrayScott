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

private let solverDispatchQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT)
private let sem = dispatch_semaphore_create(0)

private func grayScottSolverInternal(grayScottConstData: [GrayScottStruct], parameters:GrayScottParmeters, inout outputArray:[GrayScottStruct], start:Int, end:Int, completion: ()->()) {
    let initialIndex = start * Constants.LENGTH
    for i in start..<end
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
            
            let outputPixel = GrayScottStruct(u: (thisPixel.u + deltaU).clip(), v: (thisPixel.v + deltaV).clip())
            
            //outputArray.append(outputPixel)
            
            outputArray[i * Constants.LENGTH + j - initialIndex] = outputPixel;
        }
    }
    completion()
}

func grayScottSolver(grayScottConstData: [GrayScottStruct], parameters:GrayScottParmeters)->[GrayScottStruct] {
    let startTime : CFAbsoluteTime = CFAbsoluteTimeGetCurrent();
    
    let splitPoint = Constants.LENGTH / 2
    var outputArray0:[GrayScottStruct] = map(grayScottConstData[0..<(splitPoint * Constants.LENGTH)]) { $0 } // Copy to get array big enough
    var outputArray1 = outputArray0 // Another one to dispatch
    //    let sem = dispatch_semaphore_create(0)
    
    dispatch_async(solverDispatchQueue) {
        grayScottSolverInternal(grayScottConstData, parameters, &outputArray0, 0, splitPoint) { dispatch_semaphore_signal(sem); return }
    }
    dispatch_async(solverDispatchQueue) {
        grayScottSolverInternal(grayScottConstData, parameters, &outputArray1, splitPoint, Constants.LENGTH) { dispatch_semaphore_signal(sem); return }
    }
    print("dispatched")
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
    print("SEM 1")
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
    print("SEM 2")
    //    dispatch_release(sem)

    println("S  SOLVER:" + NSString(format: "%.4f", CFAbsoluteTimeGetCurrent() - startTime))
    let outputArray = outputArray0 + outputArray1
    return outputArray
}
