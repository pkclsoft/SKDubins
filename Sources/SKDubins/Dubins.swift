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
    
    enum DubinsPathType : Int {
        case LSL = 0
        case LSR
        case RSL
        case RSR
        case RLR
        case LRL
    }

    class DubinsPath {
        /* the initial configuration */
        var qi: AgentState
        /* the lengths of the three segments */
        var param: AgentState
        /* model forward velocity / model angular velocity */
        var rho: CGFloat
        /* the path type described */
        var type: DubinsPathType
        
        init(qi: AgentState, param: AgentState, rho: CGFloat, type: DubinsPathType) {
            self.qi = qi
            self.param = param
            self.rho = rho
            self.type = type
        }
    }

    enum DubinsResult {
        case EDUBOK           /* No error */
        case EDUBCOCONFIGS    /* Colocated configurations */
        case EDUBPARAM        /* Path parameterisitation error */
        case EDUBBADRHO       /* the rho value is invalid */
        case EDUBNOPATH       /* no connection between configurations with this word */
    }
    
    /**
     * Callback function for path sampling
     *
     * @note the q parameter is a configuration
     * @note the t parameter is the distance along the path
     * @note the user_data parameter is forwarded from the caller
     * @note return non-zero to denote sampling should be stopped
     */
//    typedef int (*DubinsPathSamplingCallback)(double q[3], double t, void* user_data);
    public typealias DubinsPathSamplingCallback = ((AgentState, CGFloat, Void) -> DubinsResult)

    static let EPSILON: CGFloat = (10e-10)

    enum SegmentType: Int {
        case L_SEG
        case S_SEG
        case R_SEG
    }

    /* The segment types for each of the Path types */
    let DIRDATA: [[SegmentType]] = [
        [ .L_SEG, .S_SEG, .L_SEG ],
        [ .L_SEG, .S_SEG, .R_SEG ],
        [ .R_SEG, .S_SEG, .L_SEG ],
        [ .R_SEG, .S_SEG, .R_SEG ],
        [ .R_SEG, .L_SEG, .R_SEG ],
        [ .L_SEG, .R_SEG, .L_SEG ]]

    class DubinsIntermediateResults {
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


    func dubins_word(input: DubinsIntermediateResults, pathType: DubinsPathType, output: AgentState) -> DubinsResult {
        var result: DubinsResult
        
        switch(pathType)
        {
            case .LSL:
            result = dubins_LSL(input: input, output: output)
            case .RSL:
            result = dubins_RSL(input: input, output: output)
            case .LSR:
            result = dubins_LSR(input: input, output: output)
            case .RSR:
            result = dubins_RSR(input: input, output: output)
            case .LRL:
            result = dubins_LRL(input: input, output: output)
            case .RLR:
            result = dubins_RLR(input: input, output: output)
        }
        
        return result
    }
    
    func dubins_intermediate_results(input: DubinsIntermediateResults, q0: AgentState, q1: AgentState, rho: CGFloat) -> DubinsResult {
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
    func fmodr(x: CGFloat, y: CGFloat) -> CGFloat {
        return x - y * floor(x / y);
    }

    func mod2pi(theta: CGFloat) -> CGFloat {
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
    func dubins_shortest_path(path: DubinsPath, q0: AgentState, q1: AgentState, rho: CGFloat) -> DubinsResult {
        var errcode: DubinsResult
        var input: DubinsIntermediateResults = DubinsIntermediateResults()
        var params: AgentState = AgentState()
        var cost: CGFloat
        var best_cost: CGFloat = CGFloat.infinity
        var best_word: Int = -1
        
        errcode = dubins_intermediate_results(input: input, q0: q0, q1: q1, rho: rho)
        
        if (errcode != .EDUBOK) {
            return errcode
        }

        path.qi = q0
        path.rho = rho
     
        for i in 0 ..< 6 {
            var pathType: DubinsPathType = DubinsPathType(rawValue: i)!
            errcode = dubins_word(input: input, pathType: pathType, output: params)
            
            if (errcode == .EDUBOK) {
                cost = params.pos.x + params.pos.y + params.theta
                
                if (cost < best_cost) {
                    best_word = i
                    best_cost = cost
                    path.param = params
                    path.type = pathType
                }
            }
        }
        
        if (best_word == -1) {
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
    func dubins_path(path: DubinsPath, q0: AgentState, q1: AgentState, rho: CGFloat, pathType: DubinsPathType) -> DubinsResult {
        var errcode: DubinsResult
        var input: DubinsIntermediateResults = DubinsIntermediateResults()

        errcode = dubins_intermediate_results(input: input, q0: q0, q1: q1, rho: rho)
        
        if (errcode == .EDUBOK) {
            var params: AgentState = AgentState()
            
            errcode = dubins_word(input: input, pathType: pathType, output: params)
            
            if (errcode == .EDUBOK) {
                path.param = params
                path.qi = q0
                path.rho = rho
                path.type = pathType
            }
        }
        
        return errcode
    }

    /**
     * Calculate the length of an initialised path
     *
     * @param path - the path to find the length of
     */
    func dubins_path_length(path: DubinsPath) -> CGFloat {
        var length: CGFloat = 0.0
        
        length += path.param.pos.x
        length += path.param.pos.y
        length += path.param.theta
        length = length * path.rho
        
        return length
    }

    /**
     * Return the length of a specific segment in an initialized path
     *
     * @param path - the path to find the length of
     * @param i    - the segment you to get the length of (0-2)
     */
    func dubins_segment_length(path: DubinsPath, i: Int) -> CGFloat {
        if ((i < 0) || (i > 2)) {
            return CGFloat.infinity
        }
        
        return path.param.value(atIndex: i) * path.rho
    }

    /**
     * Return the normalized length of a specific segment in an initialized path
     *
     * @param path - the path to find the length of
     * @param i    - the segment you to get the length of (0-2)
     */
    func dubins_segment_length_normalized(path: DubinsPath, i: Int) -> CGFloat {
        if( (i < 0) || (i > 2) ) {
            return .infinity
        }
        
        return path.param.value(atIndex: i)
    }

    /**
     * Extract an integer that represents which path type was used
     *
     * @param path    - an initialised path
     * @return        - one of LSL, LSR, RSL, RSR, RLR or LRL
     */
    func dubins_path_type(path: DubinsPath) -> DubinsPathType {
        return path.type
    }

    
    func dubins_segment(t: CGFloat, qi: AgentState, qt: AgentState, type: SegmentType) {
        var st: CGFloat = sin(qi.theta)
        var ct: CGFloat = cos(qi.theta)
        
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
    func dubins_path_sample(path: DubinsPath, t: CGFloat, q: AgentState) -> DubinsResult {
        /* tprime is the normalised variant of the parameter t */
        var tprime: CGFloat = t / path.rho
        var qi: AgentState = AgentState() /* The translated initial configuration */
        var q1: AgentState = AgentState() /* end-of segment 1 */
        var q2: AgentState = AgentState() /* end-of segment 2 */
        let types: [SegmentType] = DIRDATA[path.type.rawValue]
        var p1, p2: CGFloat

        if (t < 0 || t > dubins_path_length(path: path)) {
            return .EDUBPARAM
        }

        /* initial configuration */
        qi.theta = path.qi.theta

        /* generate the target configuration */
        p1 = path.param.pos.x
        p2 = path.param.pos.y
        
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
    func dubins_path_sample_many(path: DubinsPath, stepSize: CGFloat, cb: DubinsPathSamplingCallback, user_data: Void) -> DubinsResult {
        var retcode: DubinsResult = .EDUBOK

        var q: AgentState = AgentState()
        var x: CGFloat = 0.0
        var length: CGFloat = dubins_path_length(path: path)
        
        while (x <  length) {
            retcode = dubins_path_sample(path: path, t: x, q: q)
            
            if retcode != .EDUBOK {
                return retcode
            }
            
            retcode = cb(q, x, user_data)
            
            if (retcode != .EDUBOK) {
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
    func dubins_path_endpoint(path: DubinsPath, q: AgentState) -> DubinsResult {
        return dubins_path_sample(path: path, t: dubins_path_length(path: path) - Dubins.EPSILON, q: q)
    }

    /**
     * Convenience function to extract a subset of a path
     *
     * @param path    - an initialised path
     * @param t       - a length measure, where 0 < t < dubins_path_length(path)
     * @param newpath - the resultant path
     */
    func dubins_extract_subpath(path: DubinsPath, t: CGFloat, newPath: DubinsPath) -> DubinsResult {
        /* calculate the true parameter */
        var tprime: CGFloat = t / path.rho

        if ((t < 0) || (t > dubins_path_length(path: path))) {
            return .EDUBPARAM
        }

        /* copy most of the data */
        newPath.qi = path.qi
        newPath.rho = path.rho
        newPath.type  = path.type

        /* fix the parameters */
        newPath.param.pos.x = fmin(path.param.pos.x, tprime)
        newPath.param.pos.y = fmin(path.param.pos.y, tprime - newPath.param.pos.x)
        newPath.param.theta = fmin( path.param.theta, tprime - newPath.param.pos.x - newPath.param.pos.y)
        
        return .EDUBOK
    }

    func dubins_LSL(input: DubinsIntermediateResults, output: AgentState) -> DubinsResult {
        var tmp0, tmp1, p_sq: CGFloat
        
        tmp0 = input.d + input.sa - input.sb
        p_sq = 2 + input.d_sq - (2 * input.c_ab) + (2 * input.d * (input.sa - input.sb))

        if (p_sq >= 0) {
            tmp1 = atan2((input.cb - input.ca), tmp0)
            output.pos.x = mod2pi(theta: tmp1 - input.alpha)
            output.pos.y = sqrt(p_sq)
            output.theta = mod2pi(theta: input.beta - tmp1)
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }


    func dubins_RSR(input: DubinsIntermediateResults, output: AgentState) -> DubinsResult {
        var tmp0: CGFloat = input.d - input.sa + input.sb
        var p_sq: CGFloat = 2 + input.d_sq - (2 * input.c_ab) + (2 * input.d * (input.sb - input.sa))
        
        if (p_sq >= 0) {
            var tmp1: CGFloat = atan2((input.ca - input.cb), tmp0)
            output.pos.x = mod2pi(theta: input.alpha - tmp1)
            output.pos.y = sqrt(p_sq)
            output.theta = mod2pi(theta: tmp1 - input.beta)
            
            return .EDUBOK
        }
        return .EDUBNOPATH
    }

    func dubins_LSR(input: DubinsIntermediateResults, output: AgentState) -> DubinsResult {
        var p_sq: CGFloat = -2 + (input.d_sq) + (2 * input.c_ab) + (2 * input.d * (input.sa + input.sb))
        
        if (p_sq >= 0) {
            var p: CGFloat = sqrt(p_sq)
            var tmp0: CGFloat = atan2((-input.ca - input.cb), (input.d + input.sa + input.sb)) - atan2(-2.0, p)
            output.pos.x = mod2pi(theta: tmp0 - input.alpha)
            output.pos.y = p
            output.theta = mod2pi(theta: tmp0 - mod2pi(theta: input.beta))
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

    func dubins_RSL(input: DubinsIntermediateResults, output: AgentState) -> DubinsResult {
        var p_sq: CGFloat = -2 + input.d_sq + (2 * input.c_ab) - (2 * input.d * (input.sa + input.sb))
        
        if (p_sq >= 0) {
            var p: CGFloat = sqrt(p_sq)
            var tmp0: CGFloat = atan2( (input.ca + input.cb), (input.d - input.sa - input.sb) ) - atan2(2.0, p)
            output.pos.x = mod2pi(theta: input.alpha - tmp0)
            output.pos.y = p
            output.theta = mod2pi(theta: input.beta - tmp0)
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

    func dubins_RLR(input: DubinsIntermediateResults, output: AgentState) -> DubinsResult {
        var tmp0: CGFloat = (6.0 - input.d_sq + 2 * input.c_ab + 2 * input.d * (input.sa - input.sb)) / 8.0
        var phi: CGFloat  = atan2(input.ca - input.cb, input.d - input.sa + input.sb)
        
        if (abs(tmp0) <= 1) {
            var p: CGFloat = mod2pi(theta: (2.0 * CGFloat.pi) - acos(tmp0))
            var t: CGFloat = mod2pi(theta: input.alpha - phi + mod2pi(theta: p / 2.0))
            output.pos.x = t;
            output.pos.y = p;
            output.theta = mod2pi(theta: input.alpha - input.beta - t + mod2pi(theta: p));
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

    func dubins_LRL(input: DubinsIntermediateResults, output: AgentState) -> DubinsResult {
        var tmp0: CGFloat = (6.0 - input.d_sq + 2 * input.c_ab + 2 * input.d*(input.sb - input.sa)) / 8.0
        var phi: CGFloat = atan2(input.ca - input.cb, input.d + input.sa - input.sb)
        
        if (abs(tmp0) <= 1) {
            var p: CGFloat = mod2pi(theta:  2 * CGFloat.pi - acos( tmp0) );
            var t: CGFloat = mod2pi(theta: -input.alpha - phi + p / 2.0)
            output.pos.x = t
            output.pos.y = p
            output.theta = mod2pi(theta: mod2pi(theta: input.beta) - input.alpha - t + mod2pi(theta: p))
            
            return .EDUBOK
        }
        
        return .EDUBNOPATH
    }

}
