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

public struct GrayScottParameters {
    public var f : Double
    public var k : Double
    public var dU : Double
    public var dV : Double
}

private class SolverSection {
    private let startLine:Int
    private let endLine:Int
    private var gsSectionData:[GrayScottStruct]?
    private var pixelSectionData:[PixelData]?
    init(startLine:Int, endLine:Int) {
        self.startLine = startLine
        self.endLine = endLine
     /*   let items = (endLine - startLine) * Constants.LENGTH
        gsSectionData = [GrayScottStruct](count: items, repeatedValue: GrayScottStruct(u: 0, v: 0))
        pixelSectionData = [PixelData](count: items, repeatedValue:PixelData(a: 0, r:0, g: 0, b: 0)) */
    }
}

private var solverstatsCount = 0
public func grayScottSolver(grayScottConstData: [GrayScottStruct], parameters:GrayScottParameters)->([GrayScottStruct],[PixelData]) {
    
    let stats = solverstatsCount % 1024 == 0
    var startTime : CFAbsoluteTime?
    if stats {
        startTime = CFAbsoluteTimeGetCurrent();
    }
    
    let semaphore = dispatch_semaphore_create(0)
    //var queues
    
    //let queue = dispatch_queue_create("com.humanfriendly.grayscottsolver",  DISPATCH_QUEUE_CONCURRENT)
    let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
    
    let sectionSize:Int = Constants.LENGTH/solverQueues
    var sectionIndexes = map(0...solverQueues) { Int($0 * sectionSize) }
    sectionIndexes[solverQueues] = Constants.LENGTH
    var sections = [SolverSection]()
    
    for i in 0..<solverQueues {
            let section = SolverSection(startLine: sectionIndexes[i], endLine: sectionIndexes[i+1])
            sections.append(section)
            dispatch_async(queue) {
            grayScottPartialSolver(grayScottConstData, parameters, section)
            dispatch_semaphore_signal(semaphore)
        }
    }
    for i in 0..<solverQueues {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    
    if stats {
        println("S  SOLVER:" + NSString(format: "%.4f", CFAbsoluteTimeGetCurrent() - startTime!));
    }
    ++solverstatsCount
    /*
    return reduce(sections, ([GrayScottStruct](), [PixelData]())) {
        return ($0.0 + $1.gsSectionData!, $0.1 + $1.pixelSectionData!)
    }*/
    var outputGSData = [GrayScottStruct](count: Constants.LENGTH_SQUARED, repeatedValue: GrayScottStruct(u: 0, v: 0))
    var outputPixData = [PixelData](count: Constants.LENGTH_SQUARED, repeatedValue: PixelData(a: 0, r: 0, g: 0, b: 0))
    var gsIndex = 0
    var pixIndex = 0
    for section in sections  {
        for gss in section.gsSectionData! {
            outputGSData[gsIndex++] = gss
        }
        for pds in section.pixelSectionData! {
            outputPixData[pixIndex] = pds
        }
    }
    
    if stats {
        println("S  SOLVER:" + NSString(format: "%.4f", CFAbsoluteTimeGetCurrent() - startTime!));
    }
    
    return (outputGSData, outputPixData)
}

private func grayScottPartialSolver(grayScottConstData: [GrayScottStruct], parameters: GrayScottParameters, section:SolverSection) {
    
    assert(section.startLine >= 0)
    assert(section.endLine <= Constants.LENGTH)
    //assert(outputArray.count == Constants.LENGTH_SQUARED)
    assert(grayScottConstData.count == Constants.LENGTH_SQUARED)
    
    var index : Int = section.startLine * Constants.LENGTH
    
    let items = (section.endLine - section.startLine) * Constants.LENGTH
    var gsSectionData = [GrayScottStruct](count: items, repeatedValue: GrayScottStruct(u: 0, v: 0))
    var pixelSectionData = [PixelData](count: items, repeatedValue:PixelData(a: 0, r:0, g: 0, b: 0))
    
    let arrayPosition = section.startLine * Constants.LENGTH
    //println("startline: \(section.startLine), endline: \(section.endLine)")
    for i in section.startLine..<section.endLine
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
            
            let outputDataCell = GrayScottStruct(u: (thisPixel.u + deltaU).clip(), v: (thisPixel.v + deltaV).clip())
            
            let u_I = UInt8(outputDataCell.u * 255)
            let outputPos = index - arrayPosition
            pixelSectionData[outputPos].r = u_I
            pixelSectionData[outputPos].g = u_I
            pixelSectionData[outputPos].b = UInt8(outputDataCell.v * 255)
            
            gsSectionData[outputPos] = outputDataCell
            ++index
        }
        //print("\(i),")
    }
    section.gsSectionData = gsSectionData
    section.pixelSectionData = pixelSectionData
    //print("&")
}
