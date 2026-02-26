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
    private var m_myState: AgentState
    private var m_nextTrajectory: DubinsTrajectory
    private var m_goal: AgentState

    //dynamics properties
    private var m_wheelbase: CGFloat
    private var m_minRadius: CGFloat
    private var m_velocity: Int

    init(velocity: Int = 1, wheelbase: CGFloat = WHEELBASE, minRadius : CGFloat = MINRADIUS, name: String = "DubinAgent") {
        
    }
    
    func Update() -> Bool {
        if (m_nextTrajectory.controls.empty()) {
            return false
        }
        
        var nextC: Array<Control> = []
        
        for i in 0 ..< m_velocity {
            while (nextC->timesteps < 1.0 && nextC->timesteps <= 0.0){
                nextC = m_nextTrajectory.controls.erase(nextC);
                if (nextC == m_nextTrajectory.controls.end())
                    return false;
            }
            
            nextC->timesteps--;
            
            //update stuff
            //update position
            m_myState.pos.first += DELTA*cos(m_myState.theta);
            m_myState.pos.second += DELTA*sin(m_myState.theta);
            
            //get turning radius
            double turningRadius = 0.0;
            bool straightLine = true;
            
            if (abs(nextC->steeringAngle) > 1e-5){
                turningRadius = m_wheelbase / sin(nextC->steeringAngle);
                straightLine = false;
            }
            
            if(!straightLine){
                m_myState.theta += (DELTA)/turningRadius;
                if (m_myState.theta > PI)
                    m_myState.theta -= 2.0*PI;
                else if (m_myState.theta < -PI)
                            m_myState.theta += 2.0*PI;
            }
        }

        cout << "Agent state after update: "  << m_myState << endl;
        return true;
    }
    
    func SetState(start: AgentState) {
        m_myState = start
    }
    
    func SetGoal(goal: AgentState) {
        
    }
    
    func SetVelocity(velocity: Int) {
        m_velocity = velocity
    }

}
