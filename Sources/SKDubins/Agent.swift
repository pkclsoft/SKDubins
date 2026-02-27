//
//  Agent.swift
//  SKDubins
//
//  Created by Peter Easdown on 26/2/2026.
//
import Foundation
import CoreGraphics

public let WHEELBASE : CGFloat = 2.665
public let MINRADIUS : CGFloat = 6.275
public let MAXSTEER : CGFloat = asin(WHEELBASE/MINRADIUS)

//width = 2.057 m
//length = 4.1610 m
//height = 1.135 m

class AgentController {

    public func GetState() -> AgentState {
        return m_myState
    }
    
    public func GetGoal() -> AgentState {
        return m_goal
    }
    
    public func GetVelocity() -> Int {
        return m_velocity
    }

    private var m_name: String
    private var m_myState: AgentState = AgentState()
    private var m_nextTrajectory: DubinsTrajectory = DubinsTrajectory()
    private var m_goal: AgentState = AgentState()

    //dynamics properties
    private var m_wheelbase: CGFloat
    private var m_minRadius: CGFloat
    private var m_velocity: Int

    init(velocity: Int = 1, wheelbase: CGFloat = WHEELBASE, minRadius : CGFloat = MINRADIUS, name: String = "DubinAgent") {
        m_velocity = velocity
        m_name = name
        m_wheelbase = abs(wheelbase)
        m_minRadius = abs(minRadius)
    }
    
    func Update() -> Bool {
        if (m_nextTrajectory.controls.isEmpty) {
            return false
        }
        
        if var nextC: Control = m_nextTrajectory.controls.first {
            for _ in 0 ..< m_velocity {
                while (nextC.timesteps < 1.0 && nextC.timesteps <= 0.0) {
                    nextC = m_nextTrajectory.controls.removeFirst()
                    
                    if (m_nextTrajectory.controls.isEmpty) {
                        return false
                    }
                }
                
                nextC.timesteps -= 1
                
                //update stuff
                //update position
                m_myState.pos.x += DubinsCore.DELTA * cos(m_myState.theta)
                m_myState.pos.y += DubinsCore.DELTA * sin(m_myState.theta)
                
                //get turning radius
                var turningRadius: CGFloat = 0.0
                var straightLine: Bool = true
                
                if (abs(nextC.steeringAngle) > 1e-5) {
                    turningRadius = m_wheelbase / sin(nextC.steeringAngle)
                    straightLine = false
                }
                
                if (!straightLine){
                    m_myState.theta += DubinsCore.DELTA / turningRadius
                    
                    if (m_myState.theta > CGFloat.pi) {
                        m_myState.theta -= 2.0 * CGFloat.pi
                    } else if (m_myState.theta < -CGFloat.pi) {
                        m_myState.theta += 2.0 * CGFloat.pi
                    }
                }
            }
        }

        print("Agent state after update: \(m_myState.debugDescription())")
        
        return true
    }
    
    func SetState(start: AgentState) {
        m_myState = start
    }
    
    func SetGoal(goal: AgentState) {
        m_goal = goal
        
        m_nextTrajectory = Dubins.DubinsShortestPath(minTurnRadius: &m_minRadius, wheelbase: &m_wheelbase, start: &m_myState, goal: &m_goal)
    }
    
    func SetVelocity(velocity: Int) {
        m_velocity = velocity
    }

}
