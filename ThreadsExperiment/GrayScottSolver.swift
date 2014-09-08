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

private func laplacian(var initialData:[Float])->[Float] {
    var laplacian = [Float](count: initialData.count, repeatedValue: 0.0)
    var laplacianB = laplacian
    let lenSqU = UInt(Constants.LENGTH_SQUARED)
    let len_missing_line:Int = Int(lenSqU - Constants.LENGTH)
    //initialData.withUnsafeBufferPointer { (initialDataBuffer:UnsafeBufferPointer<Float>)->() in
        var minusFour = Float(-4.0)
        vDSP_vsmul(initialData, 1, &minusFour, &laplacian, 1, lenSqU)
    
        //assert(laplacian[6] == -4.0)
        // Add West
        vDSP_vadd(initialData, 1, &laplacian + 1, 1, &laplacianB + 1, 1, lenSqU - 1)
        //assert(laplacianB[6] == -3.0)
        laplacianB[0] = laplacian[0] + initialData[Constants.LENGTH_SQUARED - 1]
        // Should fix up wrapping (currently going to previous line other side.
        // Add East
        vDSP_vadd(&initialData + 1, 1, &laplacianB, 1, &laplacian, 1, lenSqU - 1)
        //assert(laplacian[6] == -2.0)
        laplacian[lenSqU - 1] = laplacianB[lenSqU - 1] + initialData[0]
        // Should fix up wrapping (currently going to previous line other side.
        // North
        vDSP_vadd(initialData, 1, &laplacian + Constants.LENGTH, 1, &laplacianB + Constants.LENGTH, 1, lenSqU - Constants.LENGTH)
        //assert(laplacianB[6] == -3.0)
        // vDSP_vadd(&initialData + len_missing_line, 1, laplacian, 1, &laplacian, 1, UInt(Constants.LENGTH))
        vDSP_vadd(laplacian, 1, &initialData + len_missing_line, 1, &laplacianB, 1, UInt(Constants.LENGTH))
        //assert(laplacianB[6] == -1.0)
        // South
        vDSP_vadd(&initialData + Constants.LENGTH, 1, &laplacianB, 1, &laplacian, 1, lenSqU - Constants.LENGTH)
        //assert(laplacian[6] == 0.0)
        vDSP_vadd(initialData, 1, &laplacianB + len_missing_line, 1, &laplacian + len_missing_line, 1, UInt(Constants.LENGTH))
        //assert(laplacian[6] == 0.0)
    
    return laplacian
}

private var solverstatsCount = 0
public func grayScottSolver(grayScottConstData: GrayScottData, parameters:GrayScottParameters)->(GrayScottData,ImageBitmap) {
    
    let stats = solverstatsCount % 1024 == 0
    var startTime : CFAbsoluteTime?
    if stats {
        startTime = CFAbsoluteTimeGetCurrent();
    }

    var outputGS = grayScottConstData//GrayScottData()//[GrayScottStruct](count: grayScottConstData.count, repeatedValue: GrayScottStruct(u: 0, v: 0))

    
    let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    
    let sectionSize:Int = Constants.LENGTH/solverQueues
    var sectionIndexes = map(0...solverQueues) { Int($0 * sectionSize) }
    sectionIndexes[solverQueues] = Constants.LENGTH
    let dispatchGroup = dispatch_group_create()
    for i in 0..<solverQueues {
            dispatch_group_async(dispatchGroup, queue) {
            grayScottPartialSolver(grayScottConstData, parameters, sectionIndexes[i], sectionIndexes[i + 1], &outputGS)
        }
    }
    dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)


    
    
    
    var outputPixels = ImageBitmap()
    var outputData_uv255 = [Float](count: Constants.LENGTH_SQUARED, repeatedValue: 0.0)
    var twoFiveFive:Float = 255.0 // Scalar multiplier to pass reference to.

    // Set outputData_uv to u * 255 then convert to Int8 and assign to R and G values in image bitmap
    vDSP_vsmul(outputGS.u_data, 1, &twoFiveFive , &outputData_uv255, 1, UInt(outputData_uv255.count))
    vDSP_vfix8 (outputData_uv255, 1, &outputPixels.data + 1, 4, UInt(outputData_uv255.count))
    // This could be a copy for less mem access
    vDSP_vfix8 (outputData_uv255, 1, &outputPixels.data + 2, 4, UInt(outputData_uv255.count))
    
    vDSP_vsmul(outputGS.v_data, 1, &twoFiveFive , &outputData_uv255, 1, UInt(outputData_uv255.count))
    vDSP_vfix8 (outputData_uv255, 1, &outputPixels.data + 3, 4, UInt(outputData_uv255.count))
    
    if stats {
        println("S  SOLVER:" + NSString(format: "%.6f", CFAbsoluteTimeGetCurrent() - startTime!));
    }
    ++solverstatsCount
    
    return (outputGS, outputPixels)
}

private func grayScottPartialSolver(grayScottConstData: GrayScottData, parameters: GrayScottParameters, startLine:Int, endLine:Int, inout outputArray: GrayScottData) {
    var reactionRateIntermediate = [Float](count: Constants.LENGTH_SQUARED, repeatedValue: 0.0)
    var reactionRate = [Float](count: Constants.LENGTH_SQUARED, repeatedValue: 0.0)
    var zero = Float(0.0)
    var one = Float(1.0)
    let lenSqU = UInt(Constants.LENGTH_SQUARED)
    vDSP_vsq(grayScottConstData.v_data, 1, &reactionRateIntermediate, 1, lenSqU)
    vDSP_vmul(grayScottConstData.u_data, 1, reactionRateIntermediate, 1, &reactionRate, 1, lenSqU)
    
    var du = parameters.dU
    var dv = parameters.dV
 
    let laplacianV = laplacian(grayScottConstData.v_data)
    var deltaVa = [Float](count: Constants.LENGTH_SQUARED, repeatedValue: 0.0)
    vDSP_vsma(laplacianV, 1, &dv, reactionRate, 1, &deltaVa, 1, lenSqU)
    
    var k = 1 - parameters.k
    vDSP_vsma(grayScottConstData.v_data, 1, &k, deltaVa, 1, &outputArray.v_data, 1, lenSqU)
    vDSP_vclip(outputArray.v_data, 1, &zero, &one, &outputArray.v_data, 1, UInt(Constants.LENGTH_SQUARED))
    
    var negData: [Float] = [Float](count: Constants.LENGTH_SQUARED, repeatedValue: 0.0)
    vDSP_vneg(grayScottConstData.u_data, 1, &negData, 1, lenSqU)
    
    vDSP_vsadd(negData, 1, &one, &negData, 1, lenSqU)
    var deltaUa = [Float](count: Constants.LENGTH_SQUARED, repeatedValue: 0.0)
    
    let laplacianU = laplacian(grayScottConstData.u_data)
    vDSP_vsmsb(laplacianU, 1, &du, reactionRate, 1, &deltaUa, 1, lenSqU)
    var f = parameters.f
    vDSP_vsma(negData, 1, &f, deltaUa, 1, &outputArray.u_data, 1, lenSqU)
    vDSP_vadd(outputArray.u_data, 1, grayScottConstData.u_data, 1, &outputArray.u_data, 1, lenSqU)
    vDSP_vclip(outputArray.u_data, 1, &zero, &one, &outputArray.u_data, 1, UInt(Constants.LENGTH_SQUARED))
}
