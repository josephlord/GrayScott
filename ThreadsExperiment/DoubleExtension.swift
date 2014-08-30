//
//  CGFloatExtension.swift
//  ThreadsExperiment
//
//  Created by Simon Gladman on 02/08/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import Foundation

extension Double
{
    func format() -> String
    {
        return NSString(format: "%.4f", Double(self));
    }
}