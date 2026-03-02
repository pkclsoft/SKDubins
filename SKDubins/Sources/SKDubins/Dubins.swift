//
//  Dubins.swift
//  SKDubins
//
//  Created by Peter Easdown on 27/2/2026.
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

public class Dubins {
    
    /**
     * Callback function for path sampling
     *
     * @note the q parameter is a configuration
     * @note the t parameter is the distance along the path
     * @note the user_data parameter is forwarded from the caller
     * @note return EDUABORT to indicate that sampling should be stopped
     */
    public typealias DubinsPathSamplingCallback = ((Configuration, CGFloat, inout Int?) -> DubinsResult)

    static let EPSILON: CGFloat = (10e-10)
    
    /// The segment type, Left, Straight, or Right
    private enum SegmentType: Int {
        case L_SEG
        case S_SEG
        case R_SEG
    }

    /* The segment types for each of the Path types */
    private static let DIRDATA: [[SegmentType]] = [
        [ .L_SEG, .S_SEG, .L_SEG ],
        [ .L_SEG, .S_SEG, .R_SEG ],
        [ .R_SEG, .S_SEG, .L_SEG ],
        [ .R_SEG, .S_SEG, .R_SEG ],
        [ .R_SEG, .L_SEG, .R_SEG ],
        [ .L_SEG, .R_SEG, .L_SEG ]]
    
    /// A simple, internal container used to house all of the parameters describing a results of part of the computation.
    private class DubinsIntermediateResults {
        var alpha: CGFloat = 0.0
        var beta: CGFloat = 0.0
        var d: CGFloat = 0.0
        var sa: CGFloat = 0.0
        var sb: CGFloat = 0.0
        var ca: CGFloat = 0.0
        var cb: CGFloat = 0.0
        var c_ab: CGFloat = 0.0
        var d_sq: CGFloat = 0.0
    }
    
    /// Computes lengths for the given path type using predefined intermediate results..
    /// - Parameters:
    ///   - input: input intermediate results allowing the lengths to be computed based on the path type.
    ///   - pathType: the path type
    ///   - output: the lengths of each segment
    /// - Returns: a status of the computation.
    private static func computeLengths(fromResults results: DubinsIntermediateResults, pathType: DubinsPathType, output: inout DubinsSegmentLengths) -> DubinsResult {
        var result: DubinsResult
        
        switch(pathType) {
            case .LSL:
                result = LSL(input: results, output: &output)
            case .RSL:
                result = RSL(input: results, output: &output)
            case .LSR:
                result = LSR(input: results, output: &output)
            case .RSR:
                result = RSR(input: results, output: &output)
            case .LRL:
                result = LRL(input: results, output: &output)
            case .RLR:
                result = RLR(input: results, output: &output)
        }
        
        return result
    }
    
    /// Computes the intermediate parameters used as input to length computations for any path type.
    /// - Parameters:
    ///   - output: the output intermediate results
    ///   - q0: the starting configuration for the path
    ///   - q1: the ending configuration for the path
    ///   - rho: forward velocity / model angular velocity
    /// - Returns: a status of the computation.
    private static func computeIntermediate(results: DubinsIntermediateResults, q0: Configuration, q1: Configuration, rho: CGFloat) -> DubinsResult {
        var dx, dy, D, d, theta, alpha, beta: CGFloat
        
        if (rho <= 0.0) {
            return .EDUBBADRHO
        }

        dx = q1.pos.x - q0.pos.x
        dy = q1.pos.y - q0.pos.y
        D = sqrt( dx * dx + dy * dy )
        d = D / rho
        theta = 0.0

        /* test required to prevent domain errors if dx=0 and dy=0 */
        if (d > 0.0) {
            theta = mod2pi(theta: atan2( dy, dx ))
        }
        
        alpha = mod2pi(theta: q0.theta - theta)
        beta  = mod2pi(theta: q1.theta - theta)

        results.alpha = alpha
        results.beta  = beta
        results.d     = d
        results.sa    = sin(alpha)
        results.sb    = sin(beta)
        results.ca    = cos(alpha)
        results.cb    = cos(beta)
        results.c_ab  = cos(alpha - beta)
        results.d_sq  = d * d

        return .EDUBOK
    }

    /**
     * Floating point modulus suitable for rings
     *
     * fmod doesn't behave correctly for angular quantities, this function does
     */
    private static func fmodr(x: CGFloat, y: CGFloat) -> CGFloat {
        return x - y * floor(x / y)
    }

    private static func mod2pi(theta: CGFloat) -> CGFloat {
        return fmodr(x: theta, y: 2 * CGFloat.pi)
    }

    ///
    /// Generate a path from an initial configuration to
    /// a target configuration, with a specified maximum turning
    /// radii.
    ///
    /// A configuration is (x, y, theta), where theta is in radians, with zero
    /// along the line x = 0, and counter-clockwise is positive
    ///
    /// - Parameters:
    ///   - path: the resultant path
    ///   - q0: a configuration specified as an array of x, y, theta
    ///   - q1: a configuration specified as an array of x, y, theta
    ///   - rho:  turning radius of the vehicle (forward velocity divided by maximum angular velocity)
    /// - Returns: a status of the computation.
    ///
    public static func shortest(path: DubinsPath, q0: Configuration, q1: Configuration, rho: CGFloat) -> DubinsResult {
        var errcode: DubinsResult
        let results: DubinsIntermediateResults = DubinsIntermediateResults()
        
        errcode = computeIntermediate(results: results, q0: q0, q1: q1, rho: rho)
        
        if (errcode != .EDUBOK) {
            return errcode
        }

        path.qi = q0
        path.rho = rho
     
        var shortestLength: CGFloat = CGFloat.infinity
        var shortestType: DubinsPathType? = nil

        for pathType in DubinsPathType.allCases {
            var params: DubinsSegmentLengths = DubinsSegmentLengths()

            errcode = computeLengths(fromResults: results, pathType: pathType, output: &params)
            
            if (errcode == .EDUBOK) {
                let length = params.totalLength()
                
                if (length < shortestLength) {
                    shortestType = pathType
                    shortestLength = length
                    
                    path.param = params
                    path.type = pathType
                }
            }
        }
        
        if (shortestType == nil) {
            return .EDUBNOPATH
        }
        
        return .EDUBOK
    }

    ///
    /// Generate a path with a specified path type from an initial configuration to
    /// a target configuration, with a specified turning radius
    ///
    /// - Parameters:
    ///   - path: the resultant path
    ///   - q0: a configuration specified as an array of x, y, theta
    ///   - q1: a configuration specified as an array of x, y, theta
    ///   - rho: turning radius of the vehicle (forward velocity divided by maximum angular velocity)
    ///   - pathType: the specific path type to use
    /// - Returns: a status of the computation.
    ///
    public static func path(path: DubinsPath, q0: Configuration, q1: Configuration, rho: CGFloat, pathType: DubinsPathType) -> DubinsResult {
        var errcode: DubinsResult
        let results: DubinsIntermediateResults = DubinsIntermediateResults()

        errcode = computeIntermediate(results: results, q0: q0, q1: q1, rho: rho)
        
        if (errcode == .EDUBOK) {
            var params: DubinsSegmentLengths = DubinsSegmentLengths()
            
            errcode = computeLengths(fromResults: results, pathType: pathType, output: &params)
            
            if (errcode == .EDUBOK) {
                path.param = params
                path.qi = q0
                path.rho = rho
                path.type = pathType
            }
        }
        
        return errcode
    }
    
    /// Computes the configuration at time `t` starting at `qi` with the specified segment type.
    /// - Parameters:
    ///   - t: the position along the length of the segment
    ///   - qi: the start configuration
    ///   - qt: the computed configuration
    ///   - type: the segment type
    private static func segment(t: CGFloat, qi: Configuration, qt: Configuration, type: SegmentType) {
        let st: CGFloat = sin(qi.theta)
        let ct: CGFloat = cos(qi.theta)
        
        if (type == .L_SEG) {
            qt.pos.x = sin(qi.theta + t) - st
            qt.pos.y = -cos(qi.theta + t) + ct
            qt.theta = t
        } else if (type == .R_SEG) {
            qt.pos.x = -sin(qi.theta - t) + st
            qt.pos.y = cos(qi.theta - t) - ct
            qt.theta = -t
        } else if (type == .S_SEG) {
            qt.pos.x = ct * t
            qt.pos.y = st * t
            qt.theta = 0.0
        }
        
        qt.pos.x += qi.pos.x
        qt.pos.y += qi.pos.y
        qt.theta += qi.theta
    }
    
    ///
    /// Calculate the configuration along the path, using the parameter t
    ///
    /// - Parameters:
    ///   - path: an initialised path
    ///   - t: a length measure, where `0 <= t < path.length()`
    ///   - q: the configuration result
    /// - Returns: a status of the computation.
    ///
    public static func sample(path: DubinsPath, t: CGFloat, q: Configuration) -> DubinsResult {
        /* tprime is the normalised variant of the parameter t */
        let tprime: CGFloat = t / path.rho
        let qi: Configuration = Configuration() /* The translated initial configuration */
        let q1: Configuration = Configuration() /* end-of segment 1 */
        let q2: Configuration = Configuration() /* end-of segment 2 */
        let types: [SegmentType] = DIRDATA[path.type!.rawValue]
        var p1, p2: CGFloat

        if !(0.0 ... path.length()).contains(t) {
            return .EDUBPARAM
        }

        /* initial configuration */
        qi.theta = path.qi.theta

        /* generate the target configuration */
        p1 = path.param.length(ofSegment: 0)
        p2 = path.param.length(ofSegment: 1)
        
        segment(t: p1, qi: qi, qt: q1, type: types[0])
        segment(t: p2, qi: q1, qt: q2, type: types[1])
        
        if (tprime < p1) {
            segment(t: tprime, qi: qi, qt: q, type: types[0])
        } else if (tprime < (p1 + p2)) {
            segment(t: tprime - p1, qi: q1, qt: q,  type: types[1])
        } else {
            segment(t: tprime - p1 - p2, qi: q2, qt: q, type: types[2])
        }

        /* scale the target configuration, translate back to the original starting point */
        q.pos.x = q.pos.x * path.rho + path.qi.pos.x
        q.pos.y = q.pos.y * path.rho + path.qi.pos.y
        q.theta = mod2pi(theta: q.theta)

        return .EDUBOK
    }

    ///
    /// Walk along the path at a fixed sampling interval, calling the
    /// callback function at each interval
    ///
    /// The sampling process continues until the whole path is sampled, or the callback returns a non-zero value
    ///
    /// - Parameters:
    ///   - path: the path to sample
    ///   - stepSize: the distance along the path for subsequent samples
    ///   - cb: the callback function to call for each sample
    ///   - user_data: optional information to pass on to the callback
    /// - Returns: a status of the computation.
    ///
    public static func sampleEntirePath(path: DubinsPath, stepSize: CGFloat, cb: DubinsPathSamplingCallback, user_data: inout Int?) -> DubinsResult {
        var retcode: DubinsResult = .EDUBOK

        let q: Configuration = Configuration()
        var x: CGFloat = 0.0
        let length: CGFloat = path.length()
        
        while (x <  length) {
            retcode = sample(path: path, t: x, q: q)
            
            if retcode != .EDUBOK {
                return retcode
            }
            
            retcode = cb(q, x, &user_data)
            
            if (retcode == .EDUBABORT) {
                return retcode
            }
            
            x += stepSize
        }
        
        return retcode
    }

    ///
    /// Convenience function to identify the endpoint of a path
    ///
    /// - Parameters:
    ///   - path: an initialised path
    ///   - q: the configuration result
    /// - Returns: a status of the computation.
    ///
    public static func endPoint(path: DubinsPath, q: Configuration) -> DubinsResult {
        return sample(path: path, t: path.length() - Dubins.EPSILON, q: q)
    }

    ///
    /// Convenience function to extract a subset of a path
    ///
    /// - Parameters:
    ///   - path: an initialised path
    ///   - t: a length measure, where `0 < t < path.length()`
    ///   - newPath: the resultant path
    /// - Returns: a status of the computation.
    ///
    public static func subPath(path: DubinsPath, t: CGFloat, newPath: DubinsPath) -> DubinsResult {
        /* calculate the true parameter */
        let tprime: CGFloat = t / path.rho

        if ((t < 0) || (t > path.length())) {
            return .EDUBPARAM
        }

        /* copy most of the data */
        newPath.qi = path.qi
        newPath.rho = path.rho
        newPath.type  = path.type

        /* fix the parameters */
        newPath.param.setLength(ofSegment: 0, to: fmin(path.param.length(ofSegment: 0), tprime))
        newPath.param.setLength(ofSegment: 1, to: fmin(path.param.length(ofSegment: 1), tprime - newPath.param.length(ofSegment: 0)))
        newPath.param.setLength(ofSegment: 2, to: fmin(path.param.length(ofSegment: 2), tprime - newPath.param.length(ofSegment: 0) - newPath.param.length(ofSegment: 1)))
        
        return .EDUBOK
    }

    private static func LSL(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        var tmp0, tmp1, p_sq: CGFloat
        
        tmp0 = input.d + input.sa - input.sb
        p_sq = 2 + input.d_sq - (2 * input.c_ab) + (2 * input.d * (input.sa - input.sb))

        if (p_sq >= 0) {
            tmp1 = atan2((input.cb - input.ca), tmp0)
            output.setLength(ofSegment: 0, to: mod2pi(theta: tmp1 - input.alpha))
            output.setLength(ofSegment: 1, to: sqrt(p_sq))
            output.setLength(ofSegment: 2, to: mod2pi(theta: input.beta - tmp1))
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }


    private static func RSR(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        let tmp0: CGFloat = input.d - input.sa + input.sb
        let p_sq: CGFloat = 2 + input.d_sq - (2 * input.c_ab) + (2 * input.d * (input.sb - input.sa))
        
        if (p_sq >= 0) {
            let tmp1: CGFloat = atan2((input.ca - input.cb), tmp0)
            output.setLength(ofSegment: 0, to: mod2pi(theta: input.alpha - tmp1))
            output.setLength(ofSegment: 1, to: sqrt(p_sq))
            output.setLength(ofSegment: 2, to: mod2pi(theta: tmp1 - input.beta))
            
            return .EDUBOK
        }
        return .EDUBNOPATH
    }

    private static func LSR(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        let p_sq: CGFloat = -2 + (input.d_sq) + (2 * input.c_ab) + (2 * input.d * (input.sa + input.sb))
        
        if (p_sq >= 0) {
            let p: CGFloat = sqrt(p_sq)
            let tmp0: CGFloat = atan2((-input.ca - input.cb), (input.d + input.sa + input.sb)) - atan2(-2.0, p)
            output.setLength(ofSegment: 0, to: mod2pi(theta: tmp0 - input.alpha))
            output.setLength(ofSegment: 1, to: p)
            output.setLength(ofSegment: 2, to: mod2pi(theta: tmp0 - mod2pi(theta: input.beta)))
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

    private static func RSL(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        let p_sq: CGFloat = -2 + input.d_sq + (2 * input.c_ab) - (2 * input.d * (input.sa + input.sb))
        
        if (p_sq >= 0) {
            let p: CGFloat = sqrt(p_sq)
            let tmp0: CGFloat = atan2( (input.ca + input.cb), (input.d - input.sa - input.sb) ) - atan2(2.0, p)
            output.setLength(ofSegment: 0, to: mod2pi(theta: input.alpha - tmp0))
            output.setLength(ofSegment: 1, to: p)
            output.setLength(ofSegment: 2, to: mod2pi(theta: input.beta - tmp0))
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

    private static func RLR(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        let tmp0: CGFloat = (6.0 - input.d_sq + 2 * input.c_ab + 2 * input.d * (input.sa - input.sb)) / 8.0
        let phi: CGFloat  = atan2(input.ca - input.cb, input.d - input.sa + input.sb)
        
        if (abs(tmp0) <= 1) {
            let p: CGFloat = mod2pi(theta: (2.0 * CGFloat.pi) - acos(tmp0))
            let t: CGFloat = mod2pi(theta: input.alpha - phi + mod2pi(theta: p / 2.0))
            output.setLength(ofSegment: 0, to: t)
            output.setLength(ofSegment: 1, to: p)
            output.setLength(ofSegment: 2, to: mod2pi(theta: input.alpha - input.beta - t + mod2pi(theta: p)))
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

    private static func LRL(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        let tmp0: CGFloat = (6.0 - input.d_sq + 2 * input.c_ab + 2 * input.d*(input.sb - input.sa)) / 8.0
        let phi: CGFloat = atan2(input.ca - input.cb, input.d + input.sa - input.sb)
        
        if (abs(tmp0) <= 1) {
            let p: CGFloat = mod2pi(theta:  2 * CGFloat.pi - acos( tmp0) )
            let t: CGFloat = mod2pi(theta: -input.alpha - phi + p / 2.0)
            output.setLength(ofSegment: 0, to: t)
            output.setLength(ofSegment: 1, to: p)
            output.setLength(ofSegment: 2, to: mod2pi(theta: mod2pi(theta: input.beta) - input.alpha - t + mod2pi(theta: p)))
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

}
