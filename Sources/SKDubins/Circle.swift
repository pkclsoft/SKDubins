//
//  Circle.swift
//  SKDubins
//
//  Created by Peter Easdown on 26/2/2026.
//
import CoreGraphics

class Circle{

    private var values: [CGFloat]

    init() {
        values = [0.0, 0.0, 0.0]
    }
  
    init(posX: CGFloat, posY: CGFloat, radius: CGFloat) {
        values = [posX, posY, radius]
	}

	func SetPos(x: CGFloat, y: CGFloat) {
		values[0] = x
		values[1] = y
	}

    func SetPos(pos: CGPoint) {
		values[0] = pos.x
		values[1] = pos.y
	}

	func SetRadius(radius: CGFloat) {
		values[2] = radius
	}

	func GetPos() -> CGPoint {
        return CGPoint(x: values[0], y: values[1])
	}
    
	func GetX() -> CGFloat {
		return values[0]
	}

    func GetY() -> CGFloat {
		return values[1]
	}

    func GetRadius() -> CGFloat {
		return values[2]
	}

    func debugDescription() -> String {
        return "Circle at point: (\(values[0]), \(values[1])) with radius = \(values[2])"
	}
}
