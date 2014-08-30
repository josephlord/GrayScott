//
//  GrayScottStruct.swift
//  ThreadsExperiment
//
//  Created by Simon Gladman on 06/08/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import Foundation

public struct GrayScottStruct {
    var u : Double = 0.0
    var v : Double = 0.0
    
    init(u : Double, v: Double)
    {
        self.u = u
        self.v = v
    }
}

public struct GrayScottData {
    var data:[GrayScottStruct]
    init() {
        data = [GrayScottStruct](count: Constants.LENGTH_SQUARED, repeatedValue: GrayScottStruct(u: 0, v: 0))
    }
    init(data:[GrayScottStruct]) {
        self.data = data
    }
    subscript(index: Int) -> GrayScottStruct {
        get {
            return data[index]
        }
        set(newValue) {
            data[index] = newValue
        }
    }
    var count:Int { get { return data.count } }
}