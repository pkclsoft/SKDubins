//
//  DubinsSegmentLengths.swift
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

/// This structure is used to store the length of each of the three segments of a path.
public struct DubinsSegmentLengths {
    
    public static let SegmentNumber = 0 ... 2
    
    /// The array of segment lengths.
    private var segmentLengths: [CGFloat]
    
    /// Initializer, starting with lengths of 0.0.
    init() {
        segmentLengths = [0.0, 0.0, 0.0]
    }
    
    /// Returns the length of the specified segment (0 .. 2)
    /// - Parameter segment: The segment number (0 .. 2)
    /// - Returns: the length of the specified segment
    func length(ofSegment segment: Int) -> CGFloat {
        assert(DubinsSegmentLengths.SegmentNumber.contains(segment))
        
        return segmentLengths[segment]
    }
    
    mutating func setLength(ofSegment segment: Int, to: CGFloat) {
        assert(DubinsSegmentLengths.SegmentNumber.contains(segment))
        
        segmentLengths[segment] = to
    }
    
    /// Returns the accumulated length of the path.
    /// - Returns: The accumulated length of all segments
    func totalLength() -> CGFloat {
        return lengthOf(segmentsInRange: DubinsSegmentLengths.SegmentNumber)
    }
    
    
    /// Returns the accumulated length of the specified segments.
    /// - Parameter segmentsInRange: the range of segments
    /// - Returns: The total length of the specified segments
    func lengthOf(segmentsInRange: ClosedRange<Int>) -> CGFloat {
        assert(DubinsSegmentLengths.SegmentNumber.overlaps(segmentsInRange))
        
        var result: CGFloat = 0.0
        
        for segmentIndex in segmentsInRange {
            result += segmentLengths[segmentIndex]
        }
        
        return result
    }
}
