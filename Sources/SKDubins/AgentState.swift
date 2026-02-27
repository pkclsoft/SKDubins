//
//  AgentState.swift
//  SKDubins
//
//  Created by Peter Easdown on 26/2/2026.
//
import CoreGraphics

class AgentState{

    init() {
      pos = CGPointZero
      theta = 0.0
    }

    func debugDescription() -> String {
        return "(\(pos.x), \(pos.y), \(theta))"
    }

    var pos: CGPoint
    var theta: CGFloat
};
