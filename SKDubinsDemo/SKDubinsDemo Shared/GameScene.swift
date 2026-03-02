//
//  GameScene.swift
//  SKDubinDemo Shared
//
//  Created by Peter Easdown on 3/12/2023.
//

import SpriteKit
import SKDubins

class GameScene: SKScene {
    
    let carSprite = SKSpriteNode(imageNamed: "car")
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFit
        
        return scene
    }
    
    func setUpScene() {
        carSprite.position = CGPointZero
        carSprite.setScale(0.3)
        
        self.addChild(carSprite)
    }
    
    override func didMove(to view: SKView) {
        self.setUpScene()
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    // to demonstrate the use of the DubinsPath, when the user taps/clicks on teh screen, teh car will
    // use a DubinPath to travel to the new position.
    //
    func target(position: CGPoint) {
        let path: DubinsPath = DubinsPath()
        
        // set up the start and end configurations.
        //
        let startConf: Configuration = Configuration(withPos: carSprite.position, andTheta: carSprite.zRotation + CGFloat.pi / 2.0)
        let endConf: Configuration = Configuration(withPos: position, andTheta: carSprite.zRotation - CGFloat.pi / 2.0)
        
        // get the shortest path
        //
        let result = Dubins.shortest(path: path, q0: startConf, q1: endConf, rho: 30.0)
        
        // if that was successfull, draw the path and send the car along it.
        //
        if result == .EDUBOK {
            if let cgPath = path.asCGPath() {
                
                carSprite.run(.follow(cgPath, asOffset: false, orientToPath: true, duration: 5.0))
                
                let pathNode = SKShapeNode(path: cgPath)
                pathNode.strokeColor = .yellow
                pathNode.lineWidth = 5.0
                pathNode.zPosition = 2.0
                pathNode.name = "fred"
                pathNode.zPosition = 200.0
                self.addChild(pathNode)
            }
        }
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            self.target(position: self.convertPoint(fromView: touch.location(in: nil)))
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
   
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
    }
    
    override func mouseDragged(with event: NSEvent) {
    }
    
    override func mouseUp(with event: NSEvent) {
        self.target(position: self.convertPoint(fromView: event.locationInWindow))
    }

}
#endif

