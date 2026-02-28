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

class Dubins {
    
    /**
     * Callback function for path sampling
     *
     * @note the q parameter is a configuration
     * @note the t parameter is the distance along the path
     * @note the user_data parameter is forwarded from the caller
     * @note return EDUABORT to denote sampling should be stopped
     */
    public typealias DubinsPathSamplingCallback = ((AgentState, CGFloat, inout Int?) -> DubinsResult)

    static let EPSILON: CGFloat = (10e-10)

    enum SegmentType: Int {
        case L_SEG
        case S_SEG
        case R_SEG
    }

    /* The segment types for each of the Path types */
    static let DIRDATA: [[SegmentType]] = [
        [ .L_SEG, .S_SEG, .L_SEG ],
        [ .L_SEG, .S_SEG, .R_SEG ],
        [ .R_SEG, .S_SEG, .L_SEG ],
        [ .R_SEG, .S_SEG, .R_SEG ],
        [ .R_SEG, .L_SEG, .R_SEG ],
        [ .L_SEG, .R_SEG, .L_SEG ]]

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

    private static func dubins_word(input: DubinsIntermediateResults, pathType: DubinsPathType, output: inout DubinsSegmentLengths) -> DubinsResult {
        var result: DubinsResult
        
        switch(pathType)
        {
            case .LSL:
            result = dubins_LSL(input: input, output: &output)
            case .RSL:
            result = dubins_RSL(input: input, output: &output)
            case .LSR:
            result = dubins_LSR(input: input, output: &output)
            case .RSR:
            result = dubins_RSR(input: input, output: &output)
            case .LRL:
            result = dubins_LRL(input: input, output: &output)
            case .RLR:
            result = dubins_RLR(input: input, output: &output)
        }
        
        return result
    }
    
    private static func dubins_intermediate_results(input: DubinsIntermediateResults, q0: AgentState, q1: AgentState, rho: CGFloat) -> DubinsResult {
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

        input.alpha = alpha
        input.beta  = beta
        input.d     = d
        input.sa    = sin(alpha)
        input.sb    = sin(beta)
        input.ca    = cos(alpha)
        input.cb    = cos(beta)
        input.c_ab  = cos(alpha - beta)
        input.d_sq  = d * d

        return .EDUBOK

    }

    /**
     * Floating point modulus suitable for rings
     *
     * fmod doesn't behave correctly for angular quantities, this function does
     */
    private static func fmodr(x: CGFloat, y: CGFloat) -> CGFloat {
        return x - y * floor(x / y);
    }

    private static func mod2pi(theta: CGFloat) -> CGFloat {
        return fmodr(x: theta, y: 2 * CGFloat.pi)
    }

    /**
     * Generate a path from an initial configuration to
     * a target configuration, with a specified maximum turning
     * radii
     *
     * A configuration is (x, y, theta), where theta is in radians, with zero
     * along the line x = 0, and counter-clockwise is positive
     *
     * @param path  - the resultant path
     * @param q0    - a configuration specified as an array of x, y, theta
     * @param q1    - a configuration specified as an array of x, y, theta
     * @param rho   - turning radius of the vehicle (forward velocity divided by maximum angular velocity)
     * @return      - non-zero on error
     */
    static func dubins_shortest_path(path: DubinsPath, q0: AgentState, q1: AgentState, rho: CGFloat) -> DubinsResult {
        var errcode: DubinsResult
        let input: DubinsIntermediateResults = DubinsIntermediateResults()
        var params: DubinsSegmentLengths = DubinsSegmentLengths()
        var cost: CGFloat
        var best_cost: CGFloat = CGFloat.infinity
        var best_word: DubinsPathType? = nil
        
        errcode = dubins_intermediate_results(input: input, q0: q0, q1: q1, rho: rho)
        
        if (errcode != .EDUBOK) {
            return errcode
        }

        path.qi = q0
        path.rho = rho
     
        for pathType in DubinsPathType.allCases {
            errcode = dubins_word(input: input, pathType: pathType, output: &params)
            
            if (errcode == .EDUBOK) {
                cost = params.totalLength()
                
                if (cost < best_cost) {
                    best_word = pathType
                    best_cost = cost
                    path.param = params
                    path.type = pathType
                }
            }
        }
        
        if (best_word == nil) {
            return .EDUBNOPATH
        }
        
        return .EDUBOK
    }

    /**
     * Generate a path with a specified word from an initial configuration to
     * a target configuration, with a specified turning radius
     *
     * @param path     - the resultant path
     * @param q0       - a configuration specified as an array of x, y, theta
     * @param q1       - a configuration specified as an array of x, y, theta
     * @param rho      - turning radius of the vehicle (forward velocity divided by maximum angular velocity)
     * @param pathType - the specific path type to use
     * @return         - non-zero on error
     */
    static func dubins_path(path: DubinsPath, q0: AgentState, q1: AgentState, rho: CGFloat, pathType: DubinsPathType) -> DubinsResult {
        var errcode: DubinsResult
        let input: DubinsIntermediateResults = DubinsIntermediateResults()

        errcode = dubins_intermediate_results(input: input, q0: q0, q1: q1, rho: rho)
        
        if (errcode == .EDUBOK) {
            var params: DubinsSegmentLengths = DubinsSegmentLengths()
            
            errcode = dubins_word(input: input, pathType: pathType, output: &params)
            
            if (errcode == .EDUBOK) {
                path.param = params
                path.qi = q0
                path.rho = rho
                path.type = pathType
            }
        }
        
        return errcode
    }
    
    static func dubins_segment(t: CGFloat, qi: AgentState, qt: AgentState, type: SegmentType) {
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
    
    /**
     * Calculate the configuration along the path, using the parameter t
     *
     * @param path - an initialised path
     * @param t    - a length measure, where 0 <= t < dubins_path_length(path)
     * @param q    - the configuration result
     * @returns    - non-zero if 't' is not in the correct range
     */
    static func dubins_path_sample(path: DubinsPath, t: CGFloat, q: AgentState) -> DubinsResult {
        /* tprime is the normalised variant of the parameter t */
        let tprime: CGFloat = t / path.rho
        let qi: AgentState = AgentState() /* The translated initial configuration */
        let q1: AgentState = AgentState() /* end-of segment 1 */
        let q2: AgentState = AgentState() /* end-of segment 2 */
        let types: [SegmentType] = DIRDATA[path.type!.rawValue]
        var p1, p2: CGFloat

        if !(0.0 ... path.length()).contains(t) {
            return .EDUBPARAM
        }

        /* initial configuration */
        qi.theta = path.qi.theta

        /* generate the target configuration */
        p1 = path.param.length[0]
        p2 = path.param.length[1]
        
        dubins_segment(t: p1, qi: qi, qt: q1, type: types[0])
        dubins_segment(t: p2, qi: q1, qt: q2, type: types[1])
        
        if (tprime < p1) {
            dubins_segment(t: tprime, qi: qi, qt: q, type: types[0])
        } else if (tprime < (p1 + p2)) {
            dubins_segment(t: tprime - p1, qi: q1, qt: q,  type: types[1])
        } else {
            dubins_segment(t: tprime - p1 - p2, qi: q2, qt: q, type: types[2])
        }

        /* scale the target configuration, translate back to the original starting point */
        q.pos.x = q.pos.x * path.rho + path.qi.pos.x
        q.pos.y = q.pos.y * path.rho + path.qi.pos.y
        q.theta = mod2pi(theta: q.theta)

        return .EDUBOK
    }

    /**
     * Walk along the path at a fixed sampling interval, calling the
     * callback function at each interval
     *
     * The sampling process continues until the whole path is sampled, or the callback returns a non-zero value
     *
     * @param path      - the path to sample
     * @param stepSize  - the distance along the path for subsequent samples
     * @param cb        - the callback function to call for each sample
     * @param user_data - optional information to pass on to the callback
     *
     * @returns - zero on successful completion, or the result of the callback
     */
    static func dubins_path_sample_many(path: DubinsPath, stepSize: CGFloat, cb: DubinsPathSamplingCallback, user_data: inout Int?) -> DubinsResult {
        var retcode: DubinsResult = .EDUBOK

        let q: AgentState = AgentState()
        var x: CGFloat = 0.0
        let length: CGFloat = path.length()
        
        while (x <  length) {
            retcode = dubins_path_sample(path: path, t: x, q: q)
            
            if retcode != .EDUBOK {
                return retcode
            }
            
            retcode = cb(q, x, &user_data)
            
            if (retcode == .EDUABORT) {
                return retcode
            }
            
            x += stepSize
        }
        
        return retcode
    }

    /**
     * Convenience function to identify the endpoint of a path
     *
     * @param path - an initialised path
     * @param q    - the configuration result
     */
    static func dubins_path_endpoint(path: DubinsPath, q: AgentState) -> DubinsResult {
        return dubins_path_sample(path: path, t: path.length() - Dubins.EPSILON, q: q)
    }

    /**
     * Convenience function to extract a subset of a path
     *
     * @param path    - an initialised path
     * @param t       - a length measure, where 0 < t < dubins_path_length(path)
     * @param newpath - the resultant path
     */
    static func dubins_extract_subpath(path: DubinsPath, t: CGFloat, newPath: DubinsPath) -> DubinsResult {
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
        newPath.param.length[0] = fmin(path.param.length[0], tprime)
        newPath.param.length[1] = fmin(path.param.length[1], tprime - newPath.param.length[0])
        newPath.param.length[2] = fmin(path.param.length[2], tprime - newPath.param.length[0] - newPath.param.length[1])
        
        return .EDUBOK
    }

    private static func dubins_LSL(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        var tmp0, tmp1, p_sq: CGFloat
        
        tmp0 = input.d + input.sa - input.sb
        p_sq = 2 + input.d_sq - (2 * input.c_ab) + (2 * input.d * (input.sa - input.sb))

        if (p_sq >= 0) {
            tmp1 = atan2((input.cb - input.ca), tmp0)
            output.length[0] = mod2pi(theta: tmp1 - input.alpha)
            output.length[1] = sqrt(p_sq)
            output.length[2] = mod2pi(theta: input.beta - tmp1)
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }


    private static func dubins_RSR(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        let tmp0: CGFloat = input.d - input.sa + input.sb
        let p_sq: CGFloat = 2 + input.d_sq - (2 * input.c_ab) + (2 * input.d * (input.sb - input.sa))
        
        if (p_sq >= 0) {
            let tmp1: CGFloat = atan2((input.ca - input.cb), tmp0)
            output.length[0] = mod2pi(theta: input.alpha - tmp1)
            output.length[1] = sqrt(p_sq)
            output.length[2] = mod2pi(theta: tmp1 - input.beta)
            
            return .EDUBOK
        }
        return .EDUBNOPATH
    }

    private static func dubins_LSR(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        let p_sq: CGFloat = -2 + (input.d_sq) + (2 * input.c_ab) + (2 * input.d * (input.sa + input.sb))
        
        if (p_sq >= 0) {
            let p: CGFloat = sqrt(p_sq)
            let tmp0: CGFloat = atan2((-input.ca - input.cb), (input.d + input.sa + input.sb)) - atan2(-2.0, p)
            output.length[0] = mod2pi(theta: tmp0 - input.alpha)
            output.length[1] = p
            output.length[2] = mod2pi(theta: tmp0 - mod2pi(theta: input.beta))
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

    private static func dubins_RSL(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        let p_sq: CGFloat = -2 + input.d_sq + (2 * input.c_ab) - (2 * input.d * (input.sa + input.sb))
        
        if (p_sq >= 0) {
            let p: CGFloat = sqrt(p_sq)
            let tmp0: CGFloat = atan2( (input.ca + input.cb), (input.d - input.sa - input.sb) ) - atan2(2.0, p)
            output.length[0] = mod2pi(theta: input.alpha - tmp0)
            output.length[1] = p
            output.length[2] = mod2pi(theta: input.beta - tmp0)
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

    private static func dubins_RLR(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        let tmp0: CGFloat = (6.0 - input.d_sq + 2 * input.c_ab + 2 * input.d * (input.sa - input.sb)) / 8.0
        let phi: CGFloat  = atan2(input.ca - input.cb, input.d - input.sa + input.sb)
        
        if (abs(tmp0) <= 1) {
            let p: CGFloat = mod2pi(theta: (2.0 * CGFloat.pi) - acos(tmp0))
            let t: CGFloat = mod2pi(theta: input.alpha - phi + mod2pi(theta: p / 2.0))
            output.length[0] = t;
            output.length[1] = p;
            output.length[2] = mod2pi(theta: input.alpha - input.beta - t + mod2pi(theta: p));
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

    private static func dubins_LRL(input: DubinsIntermediateResults, output: inout DubinsSegmentLengths) -> DubinsResult {
        let tmp0: CGFloat = (6.0 - input.d_sq + 2 * input.c_ab + 2 * input.d*(input.sb - input.sa)) / 8.0
        let phi: CGFloat = atan2(input.ca - input.cb, input.d + input.sa - input.sb)
        
        if (abs(tmp0) <= 1) {
            let p: CGFloat = mod2pi(theta:  2 * CGFloat.pi - acos( tmp0) );
            let t: CGFloat = mod2pi(theta: -input.alpha - phi + p / 2.0)
            output.length[0] = t
            output.length[1] = p
            output.length[2] = mod2pi(theta: mod2pi(theta: input.beta) - input.alpha - t + mod2pi(theta: p))
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

}
