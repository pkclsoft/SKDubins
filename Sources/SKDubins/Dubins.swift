//
//  Dubins.swift
//  SKDubins
//
//  Created by Peter Easdown on 27/2/2026.
//
import CoreGraphics

class Dubins {
    
    //calculate shortest trajectory to get to _query configuration
    public static func DubinsShortestPath(minTurnRadius: inout CGFloat, wheelbase: inout CGFloat, start: inout AgentState, goal: inout AgentState) -> DubinsTrajectory {
        var agentLeft: Circle = Circle()
        var agentRight: Circle = Circle()
        var queryLeft: Circle = Circle()
        var queryRight: Circle = Circle()
        let m_start = start
        let m_goal = goal
        let m_maxSteering = asin(wheelbase / minTurnRadius)
        let m_minTurnRadius = minTurnRadius
        
        var theta: CGFloat = m_start.theta
        theta += CGFloat.pi / 2.0
        
        if (theta > CGFloat.pi) {
            theta -= 2.0 * CGFloat.pi
        }
        
        agentLeft.SetPos(x: m_start.pos.x + m_minTurnRadius*cos(theta), y: m_start.pos.y + m_minTurnRadius*sin(theta))
        agentLeft.SetRadius(radius: m_minTurnRadius)
        
        theta = m_start.theta
        theta -= CGFloat.pi / 2.0
        
        if (theta < -CGFloat.pi) {
            theta += 2.0 * CGFloat.pi
        }
        
        agentRight.SetPos(x: m_start.pos.x + m_minTurnRadius*cos(theta), y: m_start.pos.y + m_minTurnRadius*sin(theta))
        agentRight.SetRadius(radius: m_minTurnRadius)
        
        theta = m_goal.theta
        theta += CGFloat.pi / 2.0
        
        if (theta > CGFloat.pi) {
            theta -= 2.0 * CGFloat.pi
        }
        
        queryLeft.SetPos(x: m_goal.pos.x + m_minTurnRadius*cos(theta), y: m_goal.pos.y + m_minTurnRadius*sin(theta))
        queryLeft.SetRadius(radius: m_minTurnRadius)
        
        theta = m_goal.theta
        theta -= CGFloat.pi / 2.0
        
        if (theta < -CGFloat.pi) {
            theta += 2.0 * CGFloat.pi
        }
        
        queryRight.SetPos(x: m_goal.pos.x + m_minTurnRadius*cos(theta), y: m_goal.pos.y + m_minTurnRadius*sin(theta))
        queryRight.SetRadius(radius: m_minTurnRadius)
        
        var shortest: DubinsTrajectory = DubinsTrajectory()
        var next: DubinsTrajectory = DubinsTrajectory()
        
        next = BestCSCTrajectory(m_start: m_start, m_goal: m_goal, m_minTurnRadius: m_minTurnRadius, m_maxSteering: m_maxSteering, agentLeft: &agentLeft, agentRight: &agentRight, queryLeft: &queryLeft, queryRight: &queryRight)
        
        if (next.length < shortest.length) {
            shortest = next
        }
        
        next = BestCCCTrajectory(m_start: m_start, m_goal: m_goal, m_minTurnRadius: m_minTurnRadius, m_maxSteering: m_maxSteering, agentLeft: &agentLeft,agentRight: &agentRight,queryLeft: &queryLeft,queryRight: &queryRight)
        
        if (next.length < shortest.length) {
            shortest = next
        }
        
        print("To reach query point: \(m_goal.debugDescription()) from: \(m_start.debugDescription()) Agent chose \(shortest.type) trajectory with path length: \(shortest.length)")
        
        return shortest
    }
    
    private static func BestCSCTrajectory(m_start: AgentState, m_goal: AgentState, m_minTurnRadius: CGFloat, m_maxSteering: CGFloat, agentLeft: inout Circle, agentRight: inout Circle, queryLeft: inout Circle, queryRight: inout Circle) -> DubinsTrajectory {
        let RRTangents: Array<TangentLine> = DubinsCore.TangentLines(c1: agentRight, c2: queryRight)
        let LLTangents: Array<TangentLine> = DubinsCore.TangentLines(c1: agentLeft, c2: queryLeft)
        let RLTangents: Array<TangentLine> = DubinsCore.TangentLines(c1: agentRight, c2: queryLeft)
        let LRTangents: Array<TangentLine> = DubinsCore.TangentLines(c1: agentLeft, c2: queryRight)
        
        var shortest: DubinsTrajectory = DubinsTrajectory()
        var next: DubinsTrajectory = DubinsTrajectory()
        
        ///
        /// calculate RSR
        ///
        next = RSRTrajectory(m_start: m_start, m_goal: m_goal, m_minTurnRadius: m_minTurnRadius, m_maxSteering: m_maxSteering, RRTangents: RRTangents, agentRight: &agentRight, queryRight: &queryRight)
        
        if (next.length < shortest.length) {
            shortest = next
        }
        
        ///
        /// calculate LSL
        ///
        next = LSLTrajectory(m_start: m_start, m_goal: m_goal, m_minTurnRadius: m_minTurnRadius, m_maxSteering: m_maxSteering, LLTangents: LLTangents, agentLeft: &agentLeft, queryLeft: &queryLeft)
        
        if (next.length < shortest.length) {
            shortest = next
        }
        
        ///
        /// calculate RSL
        ///
        next = RSLTrajectory(m_start: m_start, m_goal: m_goal, m_minTurnRadius: m_minTurnRadius, m_maxSteering: m_maxSteering, RLTangents: RLTangents, agentRight: &agentRight, queryLeft: &queryLeft)
        
        if (next.length < shortest.length) {
            shortest = next
        }
        
        ///
        /// calculate LSR
        ///
        next = LSRTrajectory(m_start: m_start, m_goal: m_goal, m_minTurnRadius: m_minTurnRadius, m_maxSteering: m_maxSteering, LRTangents: LRTangents, agentLeft: &agentLeft, queryRight: &queryRight)
        
        if (next.length < shortest.length) {
            shortest = next
        }
        
        return shortest
        
    }
    
    private static func BestCCCTrajectory(m_start: AgentState, m_goal: AgentState, m_minTurnRadius: CGFloat, m_maxSteering: CGFloat, agentLeft: inout Circle, agentRight: inout Circle, queryLeft: inout Circle, queryRight: inout Circle) -> DubinsTrajectory {
        var shortest: DubinsTrajectory = DubinsTrajectory()
        var next: DubinsTrajectory = DubinsTrajectory()
        
        //find the relative angle for L and right
        var theta: CGFloat = 0.0
        var D: CGFloat = DubinsCore.Norm(lhs: agentRight.GetPos(), rhs: queryRight.GetPos())
        
        ///
        /// calculate RLR
        ///
        if (D < 4.0 * m_minTurnRadius) {
            theta = acos(D / (4.0 * m_minTurnRadius))
            
            theta += atan2(queryRight.GetY() - agentRight.GetY(),  queryRight.GetX() - agentRight.GetX())
            
            next = RLRTrajectory(m_start: m_start, m_goal: m_goal, m_minTurnRadius: m_minTurnRadius, m_maxSteering: m_maxSteering, interiorTheta: &theta, agentRight: &agentRight, queryRight: &queryRight)
            
            if (next.length < shortest.length) {
                shortest = next
            }
        }
        
        ///
        /// calculate LRL
        ///
        D = DubinsCore.Norm(lhs: agentLeft.GetPos(), rhs: queryLeft.GetPos())
        
        if (D < 4.0*m_minTurnRadius) {
            theta = acos(D/(4.0 * m_minTurnRadius))
            
            theta = atan2(queryLeft.GetY() - agentLeft.GetY(),  queryLeft.GetX() - agentLeft.GetX()) - theta
            
            next = LRLTrajectory(m_start: m_start, m_goal: m_goal, m_minTurnRadius: m_minTurnRadius, m_maxSteering: m_maxSteering, interiorTheta: &theta, agentLeft: &agentLeft, queryLeft: &queryLeft)
            
            if (next.length < shortest.length) {
                shortest = next
            }
        }
        
        return shortest
    }
    
    private static func RSRTrajectory(m_start: AgentState, m_goal: AgentState, m_minTurnRadius: CGFloat, m_maxSteering: CGFloat, RRTangents: Array<TangentLine>, agentRight: inout Circle, queryRight: inout Circle) -> DubinsTrajectory {
        
        let next: DubinsTrajectory = DubinsTrajectory()
        next.type = .RSR
        
        var arcL1, arcL2, arcL3: CGFloat //arcLengths
        var nextControl: Control = Control()//for a control vector
        
        if (RRTangents.count > 0){
            //tangent pts function returns outer tangents for RR connection first
            nextControl.steeringAngle = -1.0 * m_maxSteering //right turn at max
            arcL1 = DubinsCore.ArcLength(center: agentRight.GetPos(), lhs: m_start.pos, rhs: RRTangents[0].p1, radius: m_minTurnRadius, left: false)
            
            //don't use velocities because Dubins assumes unit forward velocity
            nextControl.timesteps = arcL1 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            nextControl.steeringAngle = 0.0 //straight
            arcL2 = DubinsCore.Norm(lhs: RRTangents[0].p1, rhs: RRTangents[0].p2)
            nextControl.timesteps = arcL2 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            nextControl.steeringAngle = -1.0 * m_maxSteering //right turn at max
            arcL3 = DubinsCore.ArcLength(center: queryRight.GetPos(), lhs: RRTangents[0].p2, rhs: m_goal.pos, radius: m_minTurnRadius, left: false)
            
            nextControl.timesteps = arcL3 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            //calculate total length
            next.length =  arcL1 + arcL2 + arcL3
        }
        
        return next
    }
    
    private static func LSLTrajectory(m_start: AgentState, m_goal: AgentState, m_minTurnRadius: CGFloat, m_maxSteering: CGFloat, LLTangents: Array<TangentLine>, agentLeft: inout Circle, queryLeft: inout Circle) -> DubinsTrajectory {
        
        let next: DubinsTrajectory = DubinsTrajectory()
        next.type = .LSL
        
        var arcL1, arcL2, arcL3: CGFloat //arcLengths
        var nextControl: Control = Control()//for a control vector
        
        if (LLTangents.count > 1) {
            //tangent pts function returns outer tangents for LL connection second
            nextControl.steeringAngle = m_maxSteering //left turn at max
            arcL1 = DubinsCore.ArcLength(center: agentLeft.GetPos(), lhs: m_start.pos, rhs: LLTangents[1].p1, radius: m_minTurnRadius, left: true)
            
            //don't use velocities because Dubins assumes unit forward velocity
            nextControl.timesteps = arcL1 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            nextControl.steeringAngle = 0.0 //straight
            arcL2 = DubinsCore.Norm(lhs: LLTangents[1].p1, rhs: LLTangents[1].p2)
            nextControl.timesteps = arcL2 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            nextControl.steeringAngle = m_maxSteering //left turn at max
            arcL3 = DubinsCore.ArcLength(center: queryLeft.GetPos(), lhs: LLTangents[1].p2, rhs: m_goal.pos, radius: m_minTurnRadius, left: true)
            
            nextControl.timesteps = arcL3 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            //calculate total length
            next.length =  arcL1 + arcL2 + arcL3
        }
        return next
        
    }
    
    private static func RSLTrajectory(m_start: AgentState, m_goal: AgentState, m_minTurnRadius: CGFloat, m_maxSteering: CGFloat, RLTangents: Array<TangentLine>, agentRight: inout Circle, queryLeft: inout Circle) -> DubinsTrajectory {
        
        let next: DubinsTrajectory = DubinsTrajectory()
        next.type = .RSL
        
        var arcL1, arcL2, arcL3: CGFloat //arcLengths
        var nextControl: Control = Control()//for a control vector
        
        if (RLTangents.count > 2) {
            //tangent pts function returns inner tangents for RL connection third
            nextControl.steeringAngle = -1.0 * m_maxSteering //right turn at max
            arcL1 = DubinsCore.ArcLength(center: agentRight.GetPos(), lhs: m_start.pos, rhs: RLTangents[2].p1, radius: m_minTurnRadius, left: false)
            
            //don't use velocities because Dubins assumes unit forward velocity
            nextControl.timesteps = arcL1 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            nextControl.steeringAngle = 0.0 //straight
            arcL2 = DubinsCore.Norm(lhs: RLTangents[2].p1, rhs: RLTangents[2].p2)
            nextControl.timesteps = arcL2 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            nextControl.steeringAngle = m_maxSteering //left turn at max
            arcL3 = DubinsCore.ArcLength(center: queryLeft.GetPos(), lhs: RLTangents[2].p2, rhs: m_goal.pos, radius: m_minTurnRadius, left: true)
            
            nextControl.timesteps = arcL3 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            //calculate total length
            next.length =  arcL1 + arcL2 + arcL3
        }
        
        return next
        
    }
    
    private static func LSRTrajectory(m_start: AgentState, m_goal: AgentState, m_minTurnRadius: CGFloat, m_maxSteering: CGFloat, LRTangents: Array<TangentLine>, agentLeft: inout Circle, queryRight: inout Circle) -> DubinsTrajectory {
        
        let next: DubinsTrajectory = DubinsTrajectory()
        next.type = .LSR
        
        var arcL1, arcL2, arcL3: CGFloat //arcLengths
        var nextControl: Control = Control()//for a control vector
        
        if (LRTangents.count > 3) {
            //tangent pts function returns inner tangents for LR connection fourth
            nextControl.steeringAngle = m_maxSteering //left turn at max
            arcL1 = DubinsCore.ArcLength(center: agentLeft.GetPos(), lhs: m_start.pos, rhs: LRTangents[3].p1, radius: m_minTurnRadius, left: true)
            //don't use velocities because Dubins assumes unit forward velocity
            nextControl.timesteps = arcL1 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            nextControl.steeringAngle = 0.0 //straight
            arcL2 = DubinsCore.Norm(lhs: LRTangents[3].p1, rhs: LRTangents[3].p2)
            nextControl.timesteps = arcL2 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            nextControl.steeringAngle = -1.0 * m_maxSteering //right turn at max
            arcL3 = DubinsCore.ArcLength(center: queryRight.GetPos(), lhs: LRTangents[3].p2, rhs: m_goal.pos, radius: m_minTurnRadius, left: false)
            nextControl.timesteps = arcL3 / DubinsCore.DELTA
            next.controls.append(nextControl)
            
            //calculate total length
            next.length =  arcL1 + arcL2 + arcL3
        }
        
        return next
        
    }
    
    //interior Angle is the relative angle C3 (the third circle to turn about) is from _agentRight
    private static func RLRTrajectory(m_start: AgentState, m_goal: AgentState, m_minTurnRadius: CGFloat, m_maxSteering: CGFloat, interiorTheta: inout CGFloat, agentRight: inout Circle, queryRight: inout Circle) -> DubinsTrajectory {
        
        let next: DubinsTrajectory = DubinsTrajectory()
        next.type = .RLR
        
        var arcL1, arcL2, arcL3: CGFloat //arcLengths
        var nextControl: Control = Control()//for a control vector
        
        let lCircle: Circle = Circle()
        lCircle.SetRadius(radius: m_minTurnRadius)
        
        //compute tangent circle's pos using law of cosines + atan2 of line between agent and query circles
        lCircle.SetPos(x: agentRight.GetX() + (2.0 * m_minTurnRadius * cos(interiorTheta)), y: agentRight.GetY() +
                       (2.0 * m_minTurnRadius * sin(interiorTheta)))
        
        //compute tangent points given tangent circle
        let agentTan: CGPoint = CGPoint(x: (lCircle.GetX() + agentRight.GetX())/2.0, y: (lCircle.GetY() + agentRight.GetY())/2.0)
        let queryTan: CGPoint = CGPoint(x: (lCircle.GetX() + queryRight.GetX())/2.0, y: (lCircle.GetY() + queryRight.GetY())/2.0)
        
        
        nextControl.steeringAngle = -1.0 * m_maxSteering //right turn at max
        arcL1 = DubinsCore.ArcLength(center: agentRight.GetPos(), lhs: m_start.pos, rhs: agentTan, radius: m_minTurnRadius, left: false)
        
        //don't use velocities because Dubins assumes unit forward velocity
        nextControl.timesteps = arcL1 / DubinsCore.DELTA
        next.controls.append(nextControl)
        
        nextControl.steeringAngle = m_maxSteering //left turn at max
        arcL2 = DubinsCore.ArcLength(center: lCircle.GetPos(), lhs: agentTan, rhs: queryTan, radius: m_minTurnRadius, left: true)
        nextControl.timesteps = arcL2 / DubinsCore.DELTA
        next.controls.append(nextControl)
        
        nextControl.steeringAngle =  -1.0 * m_maxSteering //right turn at max
        arcL3 = DubinsCore.ArcLength(center: queryRight.GetPos(), lhs: queryTan, rhs: m_goal.pos, radius: m_minTurnRadius, left: false)
        nextControl.timesteps = arcL3 / DubinsCore.DELTA
        next.controls.append(nextControl)
        
        //calculate total length
        next.length =  arcL1 + arcL2 + arcL3
        
        return next
        
    }
    
    //interior Angle is the relative angle C3 (the third circle to turn about) is from _agentRight
    private static func LRLTrajectory(m_start: AgentState, m_goal: AgentState, m_minTurnRadius: CGFloat, m_maxSteering: CGFloat, interiorTheta: inout CGFloat, agentLeft: inout Circle, queryLeft: inout Circle) -> DubinsTrajectory {
        let next: DubinsTrajectory = DubinsTrajectory()
        
        next.type = .LRL
        
        var arcL1, arcL2, arcL3: CGFloat //arcLengths
        var nextControl: Control = Control() //for a control vector
        let rCircle: Circle = Circle()
        
        rCircle.SetRadius(radius: m_minTurnRadius)
        
        //compute tangent circle's pos using law of cosines + atan2 of line between agent and query circles
        rCircle.SetPos(x: agentLeft.GetX() + (2.0 * m_minTurnRadius * cos(interiorTheta)), y: agentLeft.GetY() + (2.0 * m_minTurnRadius * sin(interiorTheta)))
        
        //compute tangent points given tangent circle
        let agentTan = CGPoint(x: (rCircle.GetX() + agentLeft.GetX()) / 2.0, y: (rCircle.GetY() + agentLeft.GetY()) / 2.0)
        let queryTan = CGPoint(x: (rCircle.GetX() + queryLeft.GetX()) / 2.0, y: (rCircle.GetY() + queryLeft.GetY()) / 2.0)
        
        nextControl.steeringAngle = m_maxSteering //left turn at max
        arcL1 = DubinsCore.ArcLength(center: agentLeft.GetPos(), lhs: m_start.pos, rhs: agentTan, radius: m_minTurnRadius, left: true)
        
        //don't use velocities because Dubins assumes unit forward velocity
        nextControl.timesteps = arcL1 / DubinsCore.DELTA
        next.controls.append(nextControl)
        
        nextControl.steeringAngle = -1.0 * m_maxSteering //right turn at max
        arcL2 = DubinsCore.ArcLength(center: rCircle.GetPos(), lhs: agentTan, rhs: queryTan, radius: m_minTurnRadius, left: false)
        nextControl.timesteps = arcL2 / DubinsCore.DELTA
        next.controls.append(nextControl)
        
        nextControl.steeringAngle = m_maxSteering //left turn at max
        arcL3 = DubinsCore.ArcLength(center: queryLeft.GetPos(), lhs: queryTan, rhs: m_goal.pos, radius: m_minTurnRadius, left: true)
        nextControl.timesteps = arcL3 / DubinsCore.DELTA
        next.controls.append(nextControl)
        
        //calculate total length
        next.length =  arcL1 + arcL2 + arcL3
        return next
        
    }
}
