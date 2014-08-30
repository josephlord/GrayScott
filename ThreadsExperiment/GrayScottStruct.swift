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
    var u_data:[Double]
    var v_data:[Double]
    init() {
        u_data = [Double](count: Constants.LENGTH_SQUARED, repeatedValue: 0.0)
        v_data = [Double](count: Constants.LENGTH_SQUARED, repeatedValue: 0.0)
    }
    init(data:[GrayScottStruct]) {
        u_data = map(data) { $0.u }
        v_data = map(data) { $0.v }
    }
    subscript(index: Int) -> GrayScottStruct {
        get {
            return GrayScottStruct(u: u_data[index], v: v_data[index])
        }
        set(newValue) {
            u_data[index] = newValue.u
            v_data[index] = newValue.v
        }
    }
    var count:Int { get { return u_data.count } }

}