//
//  DubinsSegmentLengths.swift
//  SKDubins
//
//  Created by Peter Easdown on 28/2/2026.
//


import CoreGraphics

struct DubinsSegmentLengths {
        var length: [CGFloat]
        
        init() {
            length = [0.0, 0.0, 0.0]
        }
        
        func length(ofSegment segment: Int) -> CGFloat {
            return length[segment]
        }
        
        func totalLength() -> CGFloat {
            var result: CGFloat = 0.0
            
            length.forEach { segmentLength in
                result += segmentLength
            }
            
            return result
        }
    }