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
import CGExtKit

public class DubinsPath {

    /// the initial configuration
    var qi: Configuration
    /// the lengths of the three segments
    var param: DubinsSegmentLengths
    /// model forward velocity / model angular velocity
    var rho: CGFloat
    /// the path type described 
    var type: DubinsPathType?
    
    public init() {
        qi = Configuration()
        param = DubinsSegmentLengths()
        rho = 0.0
        type = nil
    }
    
    public init(qi: Configuration, param: DubinsSegmentLengths, rho: CGFloat, type: DubinsPathType) {
        self.qi = qi
        self.param = param
        self.rho = rho
        self.type = type
    }
    
    ///
    /// Calculate the length of an initialised path
    ///
    public func length() -> CGFloat {
        var length: CGFloat = self.param.totalLength()
        
        length = length * self.rho
        
        return length
    }

    
    ///
    /// Return the length of a specific segment in an initialized path
    ///
    /// - Parameter segment: the segment you to get the length of (0-2)
    /// - Returns: the length of a specific segment
    ///
    public func length(ofSegment segment: Int) -> CGFloat {
        return normalizedLength(ofSegment: segment) * self.rho
    }

    /// Returns the accumulated length of the specified segments.
    /// - Parameter segmentsInRange: the range of segments
    /// - Returns: The total length of the specified segments
    func length(ofSegmentsInRange segmentsInRange: ClosedRange<Int>) -> CGFloat {
        return normalizedLength(ofSegmentsInRange: segmentsInRange) * self.rho
    }
    
    ///
    /// Return the normalized length of a specific segment in an initialized path
    ///
    /// - Parameter segment: the segment you want to get the length of (0-2)
    /// - Returns: normalized length of a specific segment
    ///
    public func normalizedLength(ofSegment segment: Int) -> CGFloat {
        if !DubinsSegmentLengths.SegmentNumber.contains(segment) {
            return .infinity
        }
        
        return param.length(ofSegment: segment)
    }

    /// Returns the accumulated normalized length of the specified segments.
    /// - Parameter segmentsInRange: the range of segments
    /// - Returns: The total normalized length of the specified segments
    func normalizedLength(ofSegmentsInRange segmentsInRange: ClosedRange<Int>) -> CGFloat {
        if !DubinsSegmentLengths.SegmentNumber.overlaps(segmentsInRange) {
            return .infinity
        }
        
        return param.length(ofSegmentsInRange: segmentsInRange)
    }
    
    // CGPath Building
    
    private var outputPath: CGMutablePath? = nil
    private var elementCount: Int = 0
    
    private func CGPathCollectionCallback(q: Configuration, t: CGFloat, data: inout Int?) -> DubinsResult {
        if let path = outputPath {
            path.addLine(to: q.pos)
            elementCount += 1
        }
        
        return .EDUBOK
    }
    
    /// Creates a CGPath by identifying the start and end of each segment, and adding them as elements.  This keeps the path as simple as possible
    /// with a single element per path segment.
    /// - Returns: A CGPath describing the entire trajectory of the path.
    public func asCGPath() -> CGPath? {
        /// if no path type has been provided, then assume that the rest of the path is undefined.
        if self.type == nil {
            return nil
        }
        
        outputPath = CGMutablePath.init()
        outputPath?.move(to: qi.pos)
        
        /// the control point allowing us to create the curve starting at `qi` and ending at the end of the first segment.
        var firstCP: Configuration = Configuration()
        
        /// the first tangent is the point at the end of the first segment.
        var firstTangent: Configuration = Configuration()
        
        /// the second tangnt is the point at the end of the second segment.
        var secondTangent: Configuration = Configuration()
        
        /// the second control point used to create the curve from the second tangent to the final position.
        var secondCP: Configuration = Configuration()
        
        /// The final position on the path.
        var finalPosition: Configuration = Configuration()
        
        if Dubins.sample(path: self, t: self.length(ofSegment: 0), q: firstTangent) == .EDUBOK &&
            Dubins.sample(path: self, t: self.length(ofSegment: 0) / 2.0, q: firstCP) == .EDUBOK &&
            Dubins.sample(path: self, t: self.length(ofSegment: 0) + self.length(ofSegment: 1), q: secondTangent) == .EDUBOK &&
            Dubins.sample(path: self, t:  self.length(ofSegment: 0) + self.length(ofSegment: 1) + self.length(ofSegment: 2) / 2.0, q: secondCP) == .EDUBOK &&
            Dubins.sample(path: self, t:  self.length(ofSegment: 0) + self.length(ofSegment: 1) + self.length(ofSegment: 2), q: finalPosition) == .EDUBOK {
            
            firstCP.pos = CGPoint(x: 2.0 * firstCP.pos.x - 0.5 * qi.pos.x - 0.5 * firstTangent.pos.x,
                                  y: 2.0 * firstCP.pos.y - 0.5 * qi.pos.y - 0.5 * firstTangent.pos.y)
            
            secondCP.pos = CGPoint(x: 2.0 * secondCP.pos.x - 0.5 * secondTangent.pos.x - 0.5 * finalPosition.pos.x,
                                   y: 2.0 * secondCP.pos.y - 0.5 * secondTangent.pos.y - 0.5 * finalPosition.pos.y)
            
            outputPath?.addQuadCurve(to: firstTangent.pos, control: firstCP.pos)
            outputPath?.addLine(to: secondTangent.pos)
            outputPath?.addQuadCurve(to: finalPosition.pos, control: secondCP.pos)
            
            let result = outputPath
            outputPath = nil
            
            return result
        } else {
            return nil
        }
    }
}
