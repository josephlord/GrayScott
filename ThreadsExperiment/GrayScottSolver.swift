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
import Accelerate


public struct GrayScottParameters {
    public var f : Float
    public var k : Float
    public var dU : Float
    public var dV : Float
}

private var solverstatsCount = 0
public func grayScottSolver(grayScottConstData: GrayScottData, parameters:GrayScottParameters)->(GrayScottData,[PixelData]) {
    
    let stats = solverstatsCount % 1024 == 0
    var startTime : CFAbsoluteTime?
    if stats {
        startTime = CFAbsoluteTimeGetCurrent();
    }

    var outputArray = GrayScottData()//[GrayScottStruct](count: grayScottConstData.count, repeatedValue: GrayScottStruct(u: 0, v: 0))
    var outputPixels = [PixelData](count: grayScottConstData.count, repeatedValue: PixelData(a: 255, r:0, g: 0, b: 0))
    
    let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    
    let sectionSize:Int = Constants.LENGTH/solverQueues
    var sectionIndexes = map(0...solverQueues) { Int($0 * sectionSize) }
    sectionIndexes[solverQueues] = Constants.LENGTH
    let dispatchGroup = dispatch_group_create()
    for i in 0..<solverQueues {
            dispatch_group_async(dispatchGroup, queue) {
            grayScottPartialSolver(grayScottConstData, parameters, sectionIndexes[i], sectionIndexes[i + 1], &outputArray, &outputPixels)
        }
    }
    dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)
    
    if stats {
        println("S  SOLVER:" + NSString(format: "%.6f", CFAbsoluteTimeGetCurrent() - startTime!));
    }
    ++solverstatsCount
    
    return (outputArray, outputPixels)
}

private func grayScottPartialSolver(grayScottConstData: GrayScottData, parameters: GrayScottParameters, startLine:Int, endLine:Int, inout outputArray: GrayScottData, inout outputPixels:[PixelData]) {
    
    let parameter_f = [Float](count: Constants.LENGTH, repeatedValue: parameters.f)
    let parameter_k = [Float](count: Constants.LENGTH, repeatedValue: parameters.k)
    
    assert(startLine >= 0)
    assert(endLine <= Constants.LENGTH)
    assert(outputArray.count == Constants.LENGTH_SQUARED)
    assert(grayScottConstData.count == Constants.LENGTH_SQUARED)
    //let grayScottConstData = grayScottConstDataObject.data
    let grayScottConstData_u_data = grayScottConstData.u_data
    let grayScottConstData_v_data = grayScottConstData.v_data
    // :TODO: Do something for top and bottom lines
    // :TODO: Do left and right lines need fixing as the wrap is to the adjacent line
    for i in max(startLine,1) ..< min(endLine, Constants.LENGTH_MINUS_ONE)
    {
        let top = 0 == i
        let bottom = Constants.LENGTH_MINUS_ONE == i
        for j in 0 ..< Constants.LENGTH
        {
            let left = j == 0
            let right = j == Constants.LENGTH_MINUS_ONE
            let index = i * Constants.LENGTH + j
            let thisPixel = grayScottConstData[index]
            let eastPixel = grayScottConstData[index + (right ? -j : 1)]
            let westPixel = grayScottConstData[index + (left ? Constants.LENGTH_MINUS_ONE : -1)]
            let northPixel = grayScottConstData[top ? Constants.LENGTH_SQUARED - Constants.LENGTH + j : index - Constants.LENGTH]
            let southPixel = grayScottConstData[bottom ? j : index + Constants.LENGTH]
            
            let laplacianU = northPixel.u + southPixel.u + westPixel.u + eastPixel.u - (4.0 * thisPixel.u);
            let laplacianV = northPixel.v + southPixel.v + westPixel.v + eastPixel.v - (4.0 * thisPixel.v);
            let reactionRate = thisPixel.u * thisPixel.v * thisPixel.v;
            
            let deltaU : Float = parameters.dU * laplacianU - reactionRate + parameters.f * (1.0 - thisPixel.u);
            let deltaV : Float = parameters.dV * laplacianV + reactionRate - parameters.k * thisPixel.v;

            let u = thisPixel.u + deltaU
            //            let clipped_u = u < 0 ? 0 : u < 1.0 ? u : 1.0
            let v = thisPixel.v + deltaV
            //            let clipped_v = v < 0 ? 0 : v < 1.0 ? v : 1.0
            let outputDataCell = GrayScottStruct(u: u, v: v)
            /*
            let u_I = UInt8(outputDataCell.u * 255)
            outputPixels[index].r = u_I
            outputPixels[index].g = u_I
            outputPixels[index].b = UInt8(outputDataCell.v * 255)
            */
            outputArray[index] = outputDataCell
        }
    }
    let arrayLength = UInt(Constants.LENGTH_SQUARED)
    vDSP_vmin(outputArray.u_data, 1, oneArray, 1, &outputArray.u_data, 1, arrayLength)
    vDSP_vmin(outputArray.v_data, 1, oneArray, 1, &outputArray.v_data, 1, arrayLength)
    vDSP_vmax(outputArray.u_data, 1, zeroArray, 1, &outputArray.u_data, 1, arrayLength)
    vDSP_vmax(outputArray.v_data, 1, zeroArray, 1, &outputArray.v_data, 1, arrayLength)
    
    var outputData_u = twoFiveFiveArray
    vDSP_vmul(outputArray.u_data, 1, twoFiveFiveArray, 1, &outputData_u, 1, arrayLength)
    var outputData_v = twoFiveFiveArray
    vDSP_vmul(outputArray.v_data, 1, twoFiveFiveArray, 1, &outputData_v, 1, arrayLength)

    for i in startLine..<(endLine*Constants.LENGTH) {
        outputPixels[i].r = UInt8(outputData_u[i])
        outputPixels[i].g = UInt8(outputData_u[i])
        outputPixels[i].b = UInt8(outputData_v[i])
    }
}

let zeroArray = [Float](count:Constants.LENGTH_SQUARED, repeatedValue: 0.0)
let oneArray = [Float](count:Constants.LENGTH_SQUARED, repeatedValue: 1.0)
let twoFiveFiveArray = [Float](count: Constants.LENGTH_SQUARED, repeatedValue:255.0)
