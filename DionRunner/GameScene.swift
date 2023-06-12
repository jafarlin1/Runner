//
//  GameScene.swift
//  2D-Topic-2
//
//  Created by HanYi-LIN on 2023/4/24.
//

import SpriteKit
import GameplayKit
import AVFoundation
class GameScene: SKScene, SKPhysicsContactDelegate
{
    
    //節點
    var gameNode: SKNode!       //遊戲節點
    var groundNode: SKNode!     //地面節點
    var backgroundNode: SKNode! //背景節點
    var cactusNode: SKNode!     //地面陷阱節點
    var dinosaurNode: SKNode!   //恐龍節點
    var birdNode: SKNode!       //鳥節點
    
    //分數
    var scoreNode: SKLabelNode!         //分數標籤節點
    var resetInstructions: SKLabelNode! //重設指示標籤節點
    var score = 0 as Int                //分數變數

    //音效
    let backgroundMusic = SKAudioNode(fileNamed: "dino.assets/sounds/(G)I-DLE-Queencard.mp3")
    let jumpSound = SKAction.playSoundFileNamed("dino.assets/sounds/jump", waitForCompletion: false) //跳躍音效
    let dieSound = SKAction.playSoundFileNamed("dino.assets/sounds/停止音效", waitForCompletion: false) //死亡音效

    //精靈
    var dinoSprite: SKSpriteNode! //恐龍精靈節點

    //生成變數
    var spawnRate = 1.5 as Double          //生成速率
    var timeSinceLastSpawn = 0.0 as Double //距離上次生成的時間

    //一般變數
    var groundHeight: CGFloat?      //地面高度
    var dinoYPosition: CGFloat?    //恐龍Y座標
    var groundSpeed = 500 as CGFloat  //地面速度

    //常數
    let dinoHopForce = 700 as Int  //角色跳躍力量
    let cloudSpeed = 50 as CGFloat //雲朵速度
    let moonSpeed = 10 as CGFloat  //月亮速度

    let background = 0 as CGFloat //背景
    let foreground = 1 as CGFloat //前景

    //碰撞分類

    let groundCategory = 1 << 0 as UInt32 //地面碰撞分類
    let dinoCategory = 1 << 1 as UInt32   //恐龍碰撞分類
    let cactusCategory = 1 << 3 as UInt32 //地面陷阱碰撞分類
    let birdCategory = 1 << 3 as UInt32   //鳥碰撞分類
    
    override func didMove(to view: SKView) {
        
        self.backgroundColor = .white //設定背景顏色為白色
        
        self.physicsWorld.contactDelegate = self //設定物理世界的接觸代理為自己
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -9.8) //設定物理世界的重力
        
        // 背景音樂
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        // 設定音量大小
        backgroundMusic.run(SKAction.changeVolume(to: 0.3, duration: 0))
        
        //地面
        groundNode = SKNode()  //地面節點
        groundNode.zPosition = background //設定節點的Z軸位置為背景
        createAndMoveGround()  //創建並移動地面
        addCollisionToGround() //對地面添加碰撞
        
        //背景元素
        backgroundNode = SKNode() //背景節點
        backgroundNode.zPosition = background //設定節點的Z軸位置為背景
        createMoon() //創建月亮
        createClouds() //創建雲朵
        
        //恐龍
        dinosaurNode = SKNode() //恐龍節點
        dinosaurNode.zPosition = foreground //設定節點的Z軸位置為前景
        createDinosaur() //創建恐龍
        
        //地面陷阱
        cactusNode = SKNode() //地面陷阱節點
        cactusNode.zPosition = foreground //設定節點的Z軸位置為前景
        
        //鳥
        birdNode = SKNode() //鳥節點
        birdNode.zPosition = foreground //設定節點的Z軸位置為前景
        
        //分數
        score = 0 //分數初始化為0
        scoreNode = SKLabelNode(fontNamed: "Arial") //分數標籤節點
        scoreNode.fontSize = 30 //設定標籤字體大小
        scoreNode.zPosition = foreground //設定標籤的Z軸位置為前景
        scoreNode.text = "當前跑分: 0" //設定標籤的文字內容為""
        scoreNode.fontColor = SKColor.gray //設定標籤的字體顏色為灰色
        scoreNode.position = CGPoint(x: 150, y: 600) //設定標籤的位置
        
        //重置遊戲說明
        resetInstructions = SKLabelNode(fontNamed: "Arial") //建立一個以Arial字體為基底的標籤節點
        resetInstructions.fontSize = 80 //設定標籤字體大小為50
        resetInstructions.text = "點擊後 開始"
        resetInstructions.fontColor = SKColor.clear //設定標籤的字體顏色為白色
        resetInstructions.position = CGPoint(x: self.frame.midX, y: self.frame.midY) //設定標籤的位置為畫面中央的點
        
        //遊戲父節點
        gameNode = SKNode() //建立一個SKNode作為遊戲的父節點
        gameNode.addChild(groundNode) //將地面節點加入遊戲父節點中
        gameNode.addChild(backgroundNode) //將背景節點加入遊戲父節點中
        gameNode.addChild(dinosaurNode) //將恐龍節點加入遊戲父節點中
        gameNode.addChild(cactusNode) //將地面陷阱節點加入遊戲父節點中
        gameNode.addChild(birdNode) //將鳥節點加入遊戲父節點中
        gameNode.addChild(scoreNode) //將分數標籤節點加入遊戲父節點中
        gameNode.addChild(resetInstructions) //將重置說明標籤節點加入遊戲父節點中
        self.addChild(gameNode) //將遊戲父節點加入畫面中
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
      
        
        if(gameNode.speed < 1.0){ //如果遊戲速度小於1.0，表示遊戲暫停
            resetGame() //重置遊戲
            return
        }

        for _ in touches {
            if let groundPosition = dinoYPosition {
                if dinoSprite.position.y <= groundPosition && gameNode.speed > 0 { //如果恐龍在地面上且遊戲速度大於0，表示遊戲正在進行中
                    dinoSprite.physicsBody?.applyImpulse(CGVector(dx: 1, dy: dinoHopForce)) //對恐龍施加向上的力量，讓其跳躍
                    run(jumpSound) //播放跳躍音效
                }
            }
        }
    }

    
    override func update(_ currentTime: TimeInterval)
    {
    // 每個畫面渲染前呼叫的函式
        if(gameNode.speed > 0){
            groundSpeed += 0.2
            
            score += 1
            scoreNode.text = "當前跑分: \(score/5)"
            
            if(currentTime - timeSinceLastSpawn > spawnRate){
                timeSinceLastSpawn = currentTime
                spawnRate = Double.random(in: 1.0 ..< 3.5)
                
                if(Int.random(in: 0...10) < 8){
                    spawnCactus()
                } else {
                    spawnBird()
                }
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
    // 當物理接觸發生時呼叫的函式
        if(hitCactus(contact) || hitBird(contact)){
            run(dieSound)
            gameOver()
        }
    }

    func hitCactus(_ contact: SKPhysicsContact) -> Bool {
    // 判斷是否與地面陷阱接觸
        return contact.bodyA.categoryBitMask & cactusCategory == cactusCategory ||
            contact.bodyB.categoryBitMask & cactusCategory == cactusCategory
    }


    func hitBird(_ contact: SKPhysicsContact) -> Bool {
    // 判斷是否與鳥接觸
        return contact.bodyA.categoryBitMask & birdCategory == birdCategory ||
                contact.bodyB.categoryBitMask & birdCategory == birdCategory
    }
    
    
    
    
    
    func resetGame() {
        gameNode.speed = 1.0  // 遊戲速度重置為1.0
        timeSinceLastSpawn = 0.0  // 距離上一次生成經過的時間重置為0.0
        groundSpeed = 500  // 地面速度重置為500
        score = 0  // 分數重置為0
        
        cactusNode.removeAllChildren()  // 移除所有地面陷阱節點
        birdNode.removeAllChildren()  // 移除所有鳥節點
        
        resetInstructions.fontColor = SKColor.clear // 重置指示的字體顏色為白色
        // 角色跑步圖檔
        let dinoTexture1 = SKTexture(imageNamed: "dino.assets/png/Run (1)")
        let dinoTexture2 = SKTexture(imageNamed: "dino.assets/png/Run (2)")
        let dinoTexture3 = SKTexture(imageNamed: "dino.assets/png/Run (3)")
        let dinoTexture4 = SKTexture(imageNamed: "dino.assets/png/Run (4)")
        let dinoTexture5 = SKTexture(imageNamed: "dino.assets/png/Run (5)")
        let dinoTexture6 = SKTexture(imageNamed: "dino.assets/png/Run (6)")
        let dinoTexture7 = SKTexture(imageNamed: "dino.assets/png/Run (7)")
        let dinoTexture8 = SKTexture(imageNamed: "dino.assets/png/Run (8)")
        let dinoTexture9 = SKTexture(imageNamed: "dino.assets/png/Run (9)")
        let dinoTexture10 = SKTexture(imageNamed: "dino.assets/png/Run (10)")
        let dinoTexture11 = SKTexture(imageNamed: "dino.assets/png/Run (11)")
        let dinoTexture12 = SKTexture(imageNamed: "dino.assets/png/Run (12)")
        let dinoTexture13 = SKTexture(imageNamed: "dino.assets/png/Run (13)")
        let dinoTexture14 = SKTexture(imageNamed: "dino.assets/png/Run (14)")
        let dinoTexture15 = SKTexture(imageNamed: "dino.assets/png/Run (15)")
        let dinoTexture16 = SKTexture(imageNamed: "dino.assets/png/Run (16)")
        let dinoTexture17 = SKTexture(imageNamed: "dino.assets/png/Run (17)")
        let dinoTexture18 = SKTexture(imageNamed: "dino.assets/png/Run (18)")
        let dinoTexture19 = SKTexture(imageNamed: "dino.assets/png/Run (19)")
        let dinoTexture20 = SKTexture(imageNamed: "dino.assets/png/Run (20)")
        
        dinoTexture1.filteringMode = .nearest  // 設定角色紋理的濾鏡模式為最近鄰插值
        dinoTexture2.filteringMode = .nearest
        dinoTexture3.filteringMode = .nearest
        dinoTexture4.filteringMode = .nearest
        dinoTexture5.filteringMode = .nearest
        dinoTexture6.filteringMode = .nearest
        dinoTexture7.filteringMode = .nearest
        dinoTexture8.filteringMode = .nearest
        dinoTexture9.filteringMode = .nearest
        dinoTexture10.filteringMode = .nearest
        dinoTexture11.filteringMode = .nearest
        dinoTexture12.filteringMode = .nearest
        dinoTexture13.filteringMode = .nearest
        dinoTexture14.filteringMode = .nearest
        dinoTexture15.filteringMode = .nearest
        dinoTexture16.filteringMode = .nearest
        dinoTexture17.filteringMode = .nearest
        dinoTexture18.filteringMode = .nearest
        dinoTexture19.filteringMode = .nearest
        dinoTexture20.filteringMode = .nearest
        let runningAnimation = SKAction.animate(with: [dinoTexture1, dinoTexture2, dinoTexture3, dinoTexture4, dinoTexture5, dinoTexture6, dinoTexture7, dinoTexture8, dinoTexture9, dinoTexture10, dinoTexture11, dinoTexture12, dinoTexture13, dinoTexture14, dinoTexture15, dinoTexture16, dinoTexture17, dinoTexture18, dinoTexture19, dinoTexture20], timePerFrame: 0.1)  // 設定跑步動畫
        
        dinoSprite.position = CGPoint(
            x: self.frame.size.width * 0.1, y: dinoYPosition!)  // 設定角色的位置
        dinoSprite.run(SKAction.repeatForever(runningAnimation))  //角色跑步動畫，並重複播放
    }

    func gameOver() {
        gameNode.speed = 0.0  // 遊戲速度設定為0.0，達到遊戲結束效果
        
        resetInstructions.fontColor = SKColor.gray  // 重置指示的字體顏色設定為灰色
        
        let deadDinoTexture = SKTexture(imageNamed: "dino.assets/png/Idle (1)")  // 設定角色死亡的紋理
        deadDinoTexture.filteringMode = .nearest  // 設定角色死亡紋理的濾鏡模式為最近鄰插值
        
        dinoSprite.removeAllActions()  // 移除角色的所有動作
        dinoSprite.texture = deadDinoTexture  // 設定角色的紋理為死亡紋理
    }
    
    func createAndMoveGround() {
        let screenWidth = self.frame.size.width
        
        // 地面紋理
        let groundTexture = SKTexture(imageNamed: "dino.assets/landscape/ground")
        groundTexture.filteringMode = .nearest
        
        let homeButtonPadding = -30.0 as CGFloat  // 地面高度
        groundHeight = groundTexture.size().height + homeButtonPadding
        
        // 地面動作
        let moveGroundLeft = SKAction.moveBy(x: -groundTexture.size().width, y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0.0, duration: 0.0)
        let groundLoop = SKAction.sequence([moveGroundLeft, resetGround])
        
        // 地面節點
        let numberOfGroundNodes = 1 + Int(ceil(screenWidth / groundTexture.size().width))
        
        for i in 0 ..< numberOfGroundNodes {
            let node = SKSpriteNode(texture: groundTexture)
            node.anchorPoint = CGPoint(x: 0.0, y: 0.0)
            node.position = CGPoint(x: CGFloat(i) * groundTexture.size().width, y: groundHeight!)
            groundNode.addChild(node)
            node.run(SKAction.repeatForever(groundLoop))
        }
    }

    
    func addCollisionToGround() {
        let groundContactNode = SKNode()
        groundContactNode.position = CGPoint(x: 0, y: groundHeight! + 30)
        groundContactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width * 3, height: groundHeight!))
        groundContactNode.physicsBody?.friction = 0.0
        groundContactNode.physicsBody?.isDynamic = false
        groundContactNode.physicsBody?.categoryBitMask = groundCategory
        
        groundNode.addChild(groundContactNode)
    }
    
    func createMoon() {
        // 月亮紋理
        let moonTexture = SKTexture(imageNamed: "dino.assets/landscape/moon")
        let moonScale = 3.0 as CGFloat
        moonTexture.filteringMode = .nearest
        
        // 月亮精靈
        let moonSprite = SKSpriteNode(texture: moonTexture)
        moonSprite.setScale(moonScale)
        // 添加到場景
        backgroundNode.addChild(moonSprite)
        
        // 月亮動畫
        animateMoon(sprite: moonSprite, textureWidth: moonTexture.size().width * moonScale)
    }
    
    func animateMoon(sprite: SKSpriteNode, textureWidth: CGFloat) {
        let screenWidth = self.frame.size.width
        let screenHeight = self.frame.size.height
        
        let distanceOffscreen = 50.0 as CGFloat // 想將月亮從屏幕外開始
        let distanceBelowTop = 150 as CGFloat
        
        // 月亮動作
        let moveMoon = SKAction.moveBy(x: -screenWidth - textureWidth - distanceOffscreen,
                                       y: 0.0, duration: TimeInterval(screenWidth / moonSpeed))
        let resetMoon = SKAction.moveBy(x: screenWidth + distanceOffscreen, y: 0.0, duration: 0)
        let moonLoop = SKAction.sequence([moveMoon, resetMoon])
        
        sprite.position = CGPoint(x: screenWidth + distanceOffscreen, y: screenHeight - distanceBelowTop)
        sprite.run(SKAction.repeatForever(moonLoop))
    }

    func createClouds() {
        // 紋理
        let cloudTexture = SKTexture(imageNamed: "dino.assets/landscape/cloud")
        let cloudScale = 3.0 as CGFloat
        cloudTexture.filteringMode = .nearest
        
        // 雲
        let numClouds = 3
        for i in 0 ..< numClouds {
            // 創建精靈
            let cloudSprite = SKSpriteNode(texture: cloudTexture)
            cloudSprite.setScale(cloudScale)
            // 添加到場景
            backgroundNode.addChild(cloudSprite)
            
            // 動畫雲朵
            animateCloud(cloudSprite, cloudIndex: i, textureWidth: cloudTexture.size().width * cloudScale)
        }
    }
    
    func animateCloud(_ sprite: SKSpriteNode, cloudIndex i: Int, textureWidth: CGFloat) {
            let screenWidth = self.frame.size.width
            let screenHeight = self.frame.size.height
            
            let cloudOffscreenDistance = (screenWidth / 3.0) * CGFloat(i) + 100 as CGFloat // 設定雲朵起始位置在螢幕外的距離
            let cloudYPadding = 50 as CGFloat // 設定雲朵在垂直方向上的間距
            let cloudYPosition = screenHeight - (CGFloat(i) * cloudYPadding) - 200 // 設定雲朵在垂直方向上的位置
            
            let distanceToMove = screenWidth + cloudOffscreenDistance + textureWidth // 設定雲朵要移動的總距離
            
            //actions
            let moveCloud = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(distanceToMove / cloudSpeed)) // 設定雲朵移動的動作
            let resetCloud = SKAction.moveBy(x: distanceToMove, y: 0.0, duration: 0.0) // 設定雲朵重置位置的動作
            let cloudLoop = SKAction.sequence([moveCloud, resetCloud]) // 設定雲朵的循環動作
            
            sprite.position = CGPoint(x: screenWidth + cloudOffscreenDistance, y: cloudYPosition) // 設定雲朵的起始位置
            sprite.run(SKAction.repeatForever(cloudLoop)) // 執行雲朵的循環動作
        }

    func createDinosaur() {
        let screenWidth = self.frame.size.width
        let dinoScale = 0.3 as CGFloat // 設定角色的縮放比例
        
        let dinoTexture1 = SKTexture(imageNamed: "dino.assets/png/Run (1)")
        let dinoTexture2 = SKTexture(imageNamed: "dino.assets/png/Run (2)")
        let dinoTexture3 = SKTexture(imageNamed: "dino.assets/png/Run (3)")
        let dinoTexture4 = SKTexture(imageNamed: "dino.assets/png/Run (4)")
        let dinoTexture5 = SKTexture(imageNamed: "dino.assets/png/Run (5)")
        let dinoTexture6 = SKTexture(imageNamed: "dino.assets/png/Run (6)")
        let dinoTexture7 = SKTexture(imageNamed: "dino.assets/png/Run (7)")
        let dinoTexture8 = SKTexture(imageNamed: "dino.assets/png/Run (8)")
        let dinoTexture9 = SKTexture(imageNamed: "dino.assets/png/Run (9)")
        let dinoTexture10 = SKTexture(imageNamed: "dino.assets/png/Run (10)")
        let dinoTexture11 = SKTexture(imageNamed: "dino.assets/png/Run (11)")
        let dinoTexture12 = SKTexture(imageNamed: "dino.assets/png/Run (12)")
        let dinoTexture13 = SKTexture(imageNamed: "dino.assets/png/Run (13)")
        let dinoTexture14 = SKTexture(imageNamed: "dino.assets/png/Run (14)")
        let dinoTexture15 = SKTexture(imageNamed: "dino.assets/png/Run (15)")
        let dinoTexture16 = SKTexture(imageNamed: "dino.assets/png/Run (16)")
        let dinoTexture17 = SKTexture(imageNamed: "dino.assets/png/Run (17)")
        let dinoTexture18 = SKTexture(imageNamed: "dino.assets/png/Run (18)")
        let dinoTexture19 = SKTexture(imageNamed: "dino.assets/png/Run (19)")
        let dinoTexture20 = SKTexture(imageNamed: "dino.assets/png/Run (20)")
        
        dinoTexture1.filteringMode = .nearest // 設定貼圖1的濾鏡模式
        dinoTexture2.filteringMode = .nearest // 設定貼圖2的濾鏡模式
        dinoTexture3.filteringMode = .nearest // 設定貼圖3的濾鏡模式
        dinoTexture4.filteringMode = .nearest // 設定貼圖4的濾鏡模式
        dinoTexture5.filteringMode = .nearest // 設定貼圖5的濾鏡模式
        dinoTexture6.filteringMode = .nearest // 設定貼圖6的濾鏡模式
        dinoTexture7.filteringMode = .nearest // 設定貼圖7的濾鏡模式
        dinoTexture8.filteringMode = .nearest // 設定貼圖8的濾鏡模式
        dinoTexture9.filteringMode = .nearest
        dinoTexture10.filteringMode = .nearest
        dinoTexture11.filteringMode = .nearest
        dinoTexture12.filteringMode = .nearest
        dinoTexture13.filteringMode = .nearest
        dinoTexture14.filteringMode = .nearest
        dinoTexture15.filteringMode = .nearest
        dinoTexture16.filteringMode = .nearest
        dinoTexture17.filteringMode = .nearest
        dinoTexture18.filteringMode = .nearest
        dinoTexture19.filteringMode = .nearest
        dinoTexture20.filteringMode = .nearest
        
        let runningAnimation = SKAction.animate(with: [dinoTexture1, dinoTexture2, dinoTexture3, dinoTexture4, dinoTexture5, dinoTexture6, dinoTexture7, dinoTexture8, dinoTexture9, dinoTexture10, dinoTexture11, dinoTexture12, dinoTexture13, dinoTexture14, dinoTexture15, dinoTexture16, dinoTexture17, dinoTexture18, dinoTexture19, dinoTexture20], timePerFrame: 0.1)  // 設定跑步動畫
        
        dinoSprite = SKSpriteNode()
        dinoSprite.size = dinoTexture1.size() // 設定恐龍的尺寸
        dinoSprite.setScale(dinoScale) // 設定恐龍的縮放
        dinosaurNode.addChild(dinoSprite) // 將恐龍加入場景
        
        let physicsBox = CGSize(
            width: dinoTexture1.size().width * dinoScale,
            height: dinoTexture1.size().height * dinoScale)
        // 設定物理箱的大小，寬度為 dinoTexture1 寬度乘以 dinoScale，高度為 dinoTexture1 高度乘以 dinoScale
        
        dinoSprite.physicsBody = SKPhysicsBody(rectangleOf: physicsBox)
        // 設定角色的物理體為一個矩形，大小為 physicsBox
        
        dinoSprite.physicsBody?.isDynamic = true
        // 設定角色的物理體為動態的，會受到物理引擎的力學模擬
        
        dinoSprite.physicsBody?.mass = 1.0
        // 設定角色的物理質量為 1.0
        
        dinoSprite.physicsBody?.categoryBitMask = dinoCategory
        // 設定角色的物理類別掩碼為 dinoCategory
        
        dinoSprite.physicsBody?.contactTestBitMask = birdCategory | cactusCategory
        // 設定角色的碰撞檢測類別掩碼為 birdCategory 和 cactusCategory
        
        dinoSprite.physicsBody?.collisionBitMask = groundCategory
        // 設定恐龍精靈的碰撞類別掩碼為 groundCategory
        
        dinoYPosition = getGroundHeight() + dinoTexture1.size().height * dinoScale
        // 計算角色的 Y 座標位置，為地面高度加上 dinoTexture1 高度乘以 dinoScale
        
        dinoSprite.position = CGPoint(x: screenWidth * 0.15, y: dinoYPosition!)
        // 設定角色的位置為螢幕寬度的 0.15 倍，Y 座標為之前計算的 dinoYPosition
        
        dinoSprite.run(SKAction.repeatForever(runningAnimation))
        // 播放角色的持續跑步動畫
    }
    
        func spawnCactus() {
            let cactusTextures = ["cactus1", "cactus2", "cactus3", "doubleCactus", "tripleCactus"]
            let cactusScale = 0.3 as CGFloat
            // 地面陷阱紋理圖片名稱陣列和縮放比例
            
            // 紋理圖片
            let cactusTexture = SKTexture(imageNamed: "dino.assets/cacti/" + cactusTextures.randomElement()!)
            cactusTexture.filteringMode = .nearest
            // 隨機選取地面陷阱紋理圖片並設定最近濾鏡模式
            
            // 精靈
            let cactusSprite = SKSpriteNode(texture: cactusTexture)
            cactusSprite.setScale(cactusScale)
            // 設定地面陷阱的紋理圖片和縮放比例
            
            // 物理屬性
            let contactBox = CGSize(width: cactusTexture.size().width * cactusScale, height: cactusTexture.size().height * cactusScale)
            cactusSprite.physicsBody = SKPhysicsBody(rectangleOf: contactBox)
            cactusSprite.physicsBody?.isDynamic = true
            cactusSprite.physicsBody?.mass = 1.0
            cactusSprite.physicsBody?.categoryBitMask = cactusCategory
            cactusSprite.physicsBody?.contactTestBitMask = dinoCategory
            cactusSprite.physicsBody?.collisionBitMask = groundCategory
            // 設定地面陷阱的物理體屬性，包括碰撞箱大小、動態屬性、質量、碰撞和接觸檢測屬性
            
            // 添加到場景
            cactusNode.addChild(cactusSprite)
            // 將地面陷阱添加到場景中
            
            // 動畫
            animateCactus(sprite: cactusSprite, texture: cactusTexture)
            // 執行地面陷阱的動畫
        }

        func animateCactus(sprite: SKSpriteNode, texture: SKTexture) {
            let screenWidth = self.frame.size.width
            let distanceOffscreen = 10.0 as CGFloat
            let distanceToMove = screenWidth + distanceOffscreen + texture.size().width
            // 螢幕寬度、地面陷阱移出螢幕距離和地面陷阱移動距離的計算
            
            // 動作
            let moveCactus = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
            // 地面陷阱的移動動作，往左移動指定距離，持續時間根據螢幕寬度和地面速度計算
            let removeCactus = SKAction.removeFromParent()
            // 將地面陷阱從父節點中移除的動作
            let moveAndRemove = SKAction.sequence([moveCactus, removeCactus])
            // 將移動和移除動作組合成序列動作
            
            sprite.position = CGPoint(x: distanceToMove, y: getGroundHeight() + texture.size().height + 100)  //地面障礙物高度
            // 設定地面陷阱的初始位置，使其位於地面高度加上紋理圖片高度的位置
            sprite.run(moveAndRemove)
            // 執行地面陷阱的移動和移除動作
        }

        func spawnBird() {
            // 紋理圖片
            let birdTexture1 = SKTexture(imageNamed: "dino.assets/dinosaurs/flyer1")
            let birdTexture2 = SKTexture(imageNamed: "dino.assets/dinosaurs/flyer2")
            let birdScale = 1.0 as CGFloat  //圖片大小
            birdTexture1.filteringMode = .nearest
            birdTexture2.filteringMode = .nearest
            // 鳥類紋理圖片的設定
            
            // 動畫
            let screenWidth = self.frame.size.width
            let distanceOffscreen = 50.0 as CGFloat
            let distanceToMove = screenWidth + distanceOffscreen + birdTexture1.size().width * birdScale
            // 螢幕寬度、移出螢幕距離和鳥類移動距離的計算
            
            let flapAnimation = SKAction.animate(with: [birdTexture1, birdTexture2], timePerFrame: 0.5)
            // 鳥類的飛翔動畫，依序播放兩張紋理圖片，每張持續0.5秒
            let moveBird = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(screenWidth / groundSpeed))
            // 鳥類精靈的移動動作，往左移動指定距離，持續時間根據螢幕寬度和地面速度計算
            let removeBird = SKAction.removeFromParent()
            // 將鳥類精靈從父節點中移除的動作
            let moveAndRemove = SKAction.sequence([moveBird, removeBird])
            // 將移動和移除動作組合成序列動作
        
            // 設定鳥類的精靈
            let birdSprite = SKSpriteNode()
            birdSprite.size = birdTexture1.size()
            birdSprite.setScale(birdScale)

            // 設定鳥類的物理特性
            let birdContact = CGSize(
                width: birdTexture1.size().width * birdScale,
                height: birdTexture1.size().height * birdScale)
            birdSprite.physicsBody = SKPhysicsBody(rectangleOf: birdContact)
            birdSprite.physicsBody?.isDynamic = false
            birdSprite.physicsBody?.mass = 1.0
            birdSprite.physicsBody?.categoryBitMask = birdCategory
            birdSprite.physicsBody?.contactTestBitMask = dinoCategory

            // 設定鳥類的初始位置和動作
            birdSprite.position = CGPoint(
                x: distanceToMove,
                y: getGroundHeight() + birdTexture1.size().height * birdScale + 80)
            birdSprite.run(SKAction.group([moveAndRemove, SKAction.repeatForever(flapAnimation)]))

        
            // 將鳥類精靈加入場景
        birdNode.addChild(birdSprite)
    }
    
    func getGroundHeight() -> CGFloat {
        if let gHeight = groundHeight {
            return gHeight
        } else {
            print("Ground size wasn't previously calculated")
            exit(0)
        }
    }
    
}
