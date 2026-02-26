//
//  DubinsTrajectory.swift
//  SKDubins
//
//  Created by Peter Easdown on 26/2/2026.
//
import CoreGraphics

class DubinsTrajectory {
    var type: TrajectoryType
    var controls: Array<Control>
    var length: CGFloat  //path metric
    
    init() {
        type = .RSR
        length = 1e9
    }
};
