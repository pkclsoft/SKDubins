//
//  DubinsCore.swift.m
//  SKDubins
//
//  Created by Peter Easdown on 26/2/2026.
//
import CoreGraphics

class DubinsCore {
    
    private func RandDouble() -> CGFloat {
        return CGFloat.random(in: 0.0 ... CGFloat(RAND_MAX))
    }

    private func Norm(lhs: CGPoint, rhs: CGPoint) -> CGFloat {
      return sqrt((rhs.x - lhs.x) * (rhs.x - lhs.x) +
          (rhs.y - lhs.y) * (rhs.y - lhs.y));
    }

    /// Calculates outer and inner tangent lines.
    ///
    /// - Parameters:
    ///   - c1: Circle 1
    ///   - c2: Circle 2
    /// - Returns: The first two results are the outer tangents if second
    /// results exist, they are the inner tangents.
    static func TangentLines(c1: Circle, c2: Circle) -> Array<CGPoint> {
        var x1: CGFloat = c1.GetX()
        var y1: CGFloat = c1.GetY()
        var x2: CGFloat = c2.GetX()
        var y2: CGFloat = c2.GetY()
        var r1: CGFloat = c1.GetRadius()
        var r2: CGFloat = c2.GetRadius()
        var d_sq: CGFloat = pow(x2-x1,2) + pow(y2-y1,2)
        
        var returnVec : Array<CGPoint> = []
        
        if (d_sq < (r1-r2) * (r1-r2)) {
            /// we may have a problem, the circles are either intersecting, one is
            /// within the other, but still tangent at one point, or one is completely
            /// in the other. We only have a problem if one is within the other, but
            /// not tangent to it anywhere
            if (d_sq != max(r1,r2) && d_sq < max(r1,r2)) {
                print("Circles are contained with each other and not tangent. No tangent lines exist")
                return returnVec
            }
            
            // else they are intersecting or one is within the other, but still
            // tangent to it in the other two cases, either 1 or 2 external
            // tangent lines remain, but there are no internal tangent lines
        }

        var d: CGFloat = sqrt(d_sq)
        var vx: CGFloat = (x2 - x1) / d
        var vy: CGFloat = (y2 - y1) / d
        
        for sign1 in stride(from: 1.0, to: -1.0, by: -2.0) {
            var c: CGFloat = (r1 - sign1 * r2) / d
            
            if (c * c > 1.0) {
                continue //want to be subtracting small from large, not adding
            }
            
            var h: CGFloat = sqrt(max(0.0, 1.0 - c * c))

            for sign2 in stride(from: 1.0, to: -1.0, by: -2.0) {
                var nx: CGFloat = vx * c - sign2 * h * vy
                var ny: CGFloat = vy * c + sign2 * h * vx
                
                returnVec.append(CGPoint(x: x1 + r1 * nx, y: y1 + r1 * ny))
                returnVec.append(CGPoint(x: x2 + sign1 * r2 * nx, y: y2 + sign1 * r2 * ny))
            }
        }
        
        return returnVec
    }
    
    /// If lhs must turn through a negative angle and the circle direction is left, then we actually want to
    /// turn through the larger angle similarly if lhs must turn through a positive angle and the circle
    /// direction is right, then we actually want to turn through the larger angle
    ///
    /// - Parameters:
    ///   - center: the center of the arc
    ///   - lhs: left point
    ///   - rhs: right point
    ///   - radius: radius of the arc
    ///   - left: indicates a circle direction
    /// - Returns: The length of the arc
    static func ArcLength(center: CGPoint, lhs: CGPoint, rhs: CGPoint, radius: CGFloat, left: Bool) -> CGFloat {
        
        /// ArcLength is defined as the radius of the circle \* theta, the angle between
        /// the two points along the circumference
        ///
        /// Generally, you can find the short angle between the points given the circle's center point
        /// if you turn the points on the circumference into vectors from the circle center. Using the
        /// dot product of the vectors, we can determine the angle between them.
        ///
        /// However, for Dubin's cars we need to know directional information, and acos() only gives
        /// us a range of [0,PI] radians. Because circles for the Dubins cars are either right or left-turn
        /// only circles, we need to know the angle between the two points, if we were only traveling the
        /// circle's direction (left or right).
        ///
        /// Using atan2, which gives us [-PI, PI] range, we can get a positive or negative angle between
        /// our start (lhs) and goal (rhs) points.  atan2(goal) - atan2(start) will give us a positive angle if, going
        /// from start to goal we must rotate through a positive angle (regardless of circle direction). Atan2 still
        /// only gives us the short angle, but the directional information is useful. We can say that if the returned
        /// angle to rotate through is negative (right turn) but the circle's direction is positive (left turn), we'd
        /// rather have the larger angle (2PI - abs(angle_returned). Vice versa for positive angles in a
        /// right-turn circle.

        var vec1: CGPoint
        var vec2: CGPoint
        
        vec1.x = lhs.x - center.x
        vec1.y = lhs.y - center.y

        vec2.x = rhs.x - center.x
        vec2.y = rhs.y - center.y

        var theta: CGFloat = atan2(vec2.y, vec2.x) - atan2(vec1.y,vec1.x)
        
        if (theta < -1e-6 && left) {
            theta += 2.0 * CGFloat.pi
        } else if (theta > 1e-6 && !left) {
            theta -= 2.0 * CGFloat.pi
        }

        return abs(theta * radius)

    }
    
}
