//
//  DubinsPath.swift
//  SKDubins
//
//  Created by Peter Easdown on 28/2/2026.
//
// This file comprises a swift implementation of the Dubins class as found in the github
// repo:
//
//    https://github.com/AndrewWalker/Dubins-Curves/tree/master
//
// The intention of this Swift package is to provide a means to create a path using the
// mechanisms provided by Dubins-Curves that can in turn be used with a SpriteKit game
// for animating a sprite through the computed path.
//

/*
 * Copyright (c) 2008-2018, Andrew Walker
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


import CoreGraphics

class DubinsPath {
    
    
    
    /* the initial configuration */
    var qi: AgentState
    /* the lengths of the three segments */
    var param: DubinsSegmentLengths
    /* model forward velocity / model angular velocity */
    var rho: CGFloat
    /* the path type described */
    var type: DubinsPathType?
    
    init() {
        qi = AgentState()
        param = DubinsSegmentLengths()
        rho = 0.0
        type = nil
    }
    
    init(qi: AgentState, param: DubinsSegmentLengths, rho: CGFloat, type: DubinsPathType) {
        self.qi = qi
        self.param = param
        self.rho = rho
        self.type = type
    }
    
    /**
     * Calculate the length of an initialised path
     */
    func length() -> CGFloat {
        var length: CGFloat = self.param.totalLength()
        
        length = length * self.rho
        
        return length
    }

    
    /**
     * Return the length of a specific segment in an initialized path
     *
     * @param segment   - the segment you to get the length of (0-2)
     */
    func length(ofSegment segment: Int) -> CGFloat {
        return normalizedSegmentLength(ofSegment: segment) * self.rho
    }

    /**
     * Return the normalized length of a specific segment in an initialized path
     *
     * @param segment    - the segment you want to get the length of (0-2)
     */
    func normalizedSegmentLength(ofSegment segment: Int) -> CGFloat {
        if !(0 ... 2).contains(segment) {
            return .infinity
        }
        
        return param.length(ofSegment: segment)
    }

}
