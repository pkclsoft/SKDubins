//
//  AgentState.swift
//  SKDubins
//
//  Created by Peter Easdown on 26/2/2026.
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
import CGExtKit

/// A configuration describes (typically) the start and end of the path.  It can also be used (and is) to
/// describe a sampled point along the path.
class Configuration {
    
    /// Initialises an empty/default configuration.
    init() {
        pos = CGPointZero
        theta = 0.0
    }
    
    init(withPos: CGPoint, andTheta: CGFloat) {
        pos = withPos
        theta = andTheta
    }
    
    /// Returns a string representation of the object.
    /// - Returns: A simple string.
    func debugDescription() -> String {
        return "(\(pos.x), \(pos.y), \(theta))"
    }
    
    /// The position of the configuration along the path.
    var pos: CGPoint
    /// The heading of the agent at the position provided by `pos`.
    var theta: CGFloat
}

extension Configuration {
    
    static func == (left: Configuration, right: Configuration) -> Bool {
        return CGPoint.equals(left.pos, right.pos) && CGFloat.equals(left.theta, right.theta)
    }
    
}
