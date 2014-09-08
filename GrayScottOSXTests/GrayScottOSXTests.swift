//
//  GrayScottOSXTests.swift
//  GrayScottOSXTests
//
//  Created by Joseph on 22/08/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import Cocoa
import XCTest
import Accelerate

var testData: [Float] = {
    var t = [Float](count: 1024 * 1024, repeatedValue: 0)
    var i = 0
    t = t.map { (f:Float)-> Float in return Float(i++) }
    return t
}()

class GrayScottOSXTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    
    func testWholeArrayMultiplicationAccelerate() {
        var outputData = testData // copy array to get one the same size
        outputData[0] = 0.0 // Force copy before measureBlock.
        self.measureBlock {
            vDSP_vmul(testData, 1, testData, 1, &outputData, 1, UInt(testData.count))
        }
        println(outputData[20..<25])
        XCTAssertEqual(outputData[888], testData[888] * testData[888])
        XCTAssertEqual(outputData[888], 888.0 * 888.0)
    }
    
    func testWholeArrayMultiplication() {
        var outputData = testData // copy array to get one the same size
        outputData[0] = 0.0 // Force copy before measureBlock.
        self.measureBlock {
            for i in 0..<1024 { // Only do 1/1024 of the full array.
                outputData[i] = testData[i] * testData[i]
            }
        }
        println(outputData[20..<25])
        XCTAssertEqual(outputData[888], testData[888] * testData[888])
    }
 /*
    func testSplitArrayMultiplicationAccelerate() {
        var outputData = testData // copy array to get one the same size
        outputData[0] = 0.0 // Force copy before measureBlock.
        let i = 0
        let offset = i * 1024
        self.measureBlock {
            //   for i in 0..<(testData.count / 1024) {
            //let i = 0 ; if true {
            
            //
                vDSP_vmul(&testData/* + offset*/, 1, &testData /*+ offset*/, 1, &outputData /*+ offset*/, 1, UInt(testData.count))
            //}
        }
        println(outputData[20..<25])
        XCTAssertEqual(outputData[888], testData[888] * testData[888])
    }
    */
    func testFloat2CharAccelerate() {
        var outputData = [Int8](count: testData.count, repeatedValue: 0)
        outputData[0] = 0 // Force copy before measureBlock.
        self.measureBlock {
            vDSP_vfix8(testData, 1, &outputData, 1, UInt(testData.count))
        }
        println(outputData[20..<25])
        XCTAssertEqual(outputData[888], 120)
    }
}
