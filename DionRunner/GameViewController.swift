//  GameViewController.swift
//  2D-Topic-2
//
//  Created by HanYi-LIN on 2023/4/24.

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            
            if let scene = SKScene(fileNamed: "GameScene") {
                scene.scaleMode = .aspectFill
                
                let background = SKSpriteNode(imageNamed: "southeast")
                        background.position = CGPoint(x: scene.size.width / 2 , y: scene.size.height / 2)
                        background.zPosition = -1 // 确保背景位于场景的最底层
                        scene.addChild(background)
                background.setScale(max(scene.size.width, scene.size.height) / max(background.size.width, background.size.height))
                
                
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .landscapeRight
        .landscape
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
