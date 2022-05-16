import SwiftUI
import SpriteKit

// Add name, stats, and description

class ShopScene: SKScene, UIScrollViewDelegate {
    
    var font = "AmericanTypewriter-Bold" 
    var currentShip = UserDefaults.standard.integer(forKey: "ship")
    var coins = UserDefaults.standard.integer(forKey: "savedCoins")
    
    override func didMove(to view: SKView) {
        let cost = (currentShip + 1) * (currentShip + 1) * 5
        
        //Scene settings
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
        generateBackground(scene: self, size: 1, speed: 100)
        let size = relativeSize(scene: self)
        
        // UI
        
        generateCoinLabel(coins: coins, scene: self)
        
        //    Bottom bar
        
        let bottomBar = SKSpriteNode(color: .systemBlue, size: CGSize(width: frame.width, height: size * 1.5))
        bottomBar.anchorPoint = CGPoint(x: 0.5, y: 0)
        bottomBar.position = (CGPoint(x: 0, y: frame.minY))
        bottomBar.zPosition = -1
        addChild(bottomBar)
        
        //    Top bar
        
        let topBar = SKSpriteNode(color: .systemBlue, size: CGSize(width: frame.width, height: size * 1.5))
        topBar.anchorPoint = CGPoint(x: 0.5, y: 1)
        topBar.position = (CGPoint(x: 0, y: frame.maxY))
        topBar.zPosition = -1
        addChild(topBar)
        
        //    Back button
        
        let backLabel = SKLabelNode(text: "back to menu")
        backLabel.horizontalAlignmentMode = .left
        backLabel.fontSize = size / 2
        backLabel.fontName = font
        backLabel.fontColor = .white
        backLabel.position = CGPoint(x: frame.minX + size / 2, y: frame.minY + size / 2)
        backLabel.name = "back"
        addChild(backLabel)
        
        //    Title
        
        let titleLabel = SKLabelNode(text: "upgrade")
        titleLabel.fontSize = size
        titleLabel.fontName = font
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: frame.maxY - size)
        addChild(titleLabel)
        
        //    Ship preview
        
        let shipBackground = SKSpriteNode(color: .systemBlue, size: CGSize(width: size * 5, height: size * 5))
        shipBackground.position = CGPoint(x: 0, y: 0)
        shipBackground.drawBorder(color: .white, width: 8)
        let shipImage = SKSpriteNode(imageNamed: "player\(currentShip + 1)")
        
        //    Buy Button
        
        var buyColor: UIColor
        if coins >= cost {
            buyColor = .systemGreen
        } else {
            buyColor = .systemGray
        }
        let buyBackground = SKSpriteNode(color: buyColor, size: CGSize(width: size * 3, height: size * 1.5))
        buyBackground.drawBorder(color: .white, width: 8)
        buyBackground.name = "buy"
        let buyLabel = SKLabelNode(text:"\(cost)")
        buyLabel.name = "buyLabel"
        buyLabel.color = .white
        buyLabel.fontSize = size
        buyLabel.fontName = font
        buyLabel.verticalAlignmentMode = .center
        buyLabel.horizontalAlignmentMode = .right
        buyLabel.position.x += 10
        let buyIcon = SKSpriteNode(imageNamed: "coin.png")
        buyIcon.name = "buyIcon"
        buyIcon.size = CGSize(width: size * 0.8, height: size * 0.8)
        buyIcon.anchorPoint = CGPoint(x: -0.35, y: 0.5)
        if frame.maxX < frame.maxY {
            buyBackground.position = CGPoint(x: 0, y: (frame.midY + bottomBar.position.y) / 2)
        } else {
            shipBackground.position = CGPoint(x: frame.minX / 3, y: 0)
            buyBackground.position = CGPoint(x: frame.maxX / 3, y: 0)
        }
        
        // Ship preview size animation
        
        shipImage.size = CGSize(width: size * 4, height: size * 4)
        let animation1 = SKAction.moveBy(x: 0, y: 5, duration: 1.0)
        animation1.timingMode = .easeInEaseOut
        let animation2 = SKAction.moveBy(x: 0, y: -5, duration: 1.0)
        animation2.timingMode = .easeInEaseOut
        shipImage.run(SKAction.repeatForever(SKAction.sequence([animation1, animation2])))
        addChild(shipBackground)
        
        // Check if an upgrade is available
        
        if currentShip + 1 < 3 {
            shipBackground.addChild(shipImage)
            addChild(buyBackground)
            buyBackground.addChild(buyLabel)
        } else {
            shipImage.texture = SKTexture(imageNamed: "player\(currentShip).png")
            shipBackground.addChild(shipImage)
            let maxLabel = SKLabelNode(text: "MAXED")
            maxLabel.fontColor = .white
            maxLabel.verticalAlignmentMode = .center
            maxLabel.fontName = font
            shipBackground.addChild(maxLabel)
        }
        buyBackground.addChild(buyIcon)
        
        // Delay audio
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [self] (_) in
            let backgroundMusic = SKAudioNode(fileNamed: "shop_theme.mp3")
            backgroundMusic.run(SKAction.changeVolume(by: -0.92, duration: 0))
            addChild(backgroundMusic)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = self.nodes(at: location)
            
            // Check if the Back label or Buy label was touched
            
            for node in touchedNode {
                if node.name == "back" {
                    let gameScene = GameScene(size: self.view!.bounds.size)
                    gameScene.scaleMode = .resizeFill
                    gameScene.lives = 0
                    let animation = SKTransition.fade(withDuration: 1.0)
                    self.view?.presentScene(gameScene, transition: animation)
                } else if node.name == "buy" {
                    
                    // Check if player has enough coins
                    
                    if coins >= (currentShip + 1) * (currentShip + 1) * 5 {
                        let boughtLabel = node.copy() as! SKSpriteNode
                        node.run(SKAction.sequence([SKAction.fadeAlpha(by: -0.2, duration: 0.1), SKAction.fadeAlpha(by: 0.2, duration: 0.1), SKAction.removeFromParent()]))
                        boughtLabel.name = ""
                        boughtLabel.enumerateChildNodes(withName: "buyLabel") { (node, stop) in
                            let buyLabel = node as! SKLabelNode
                            buyLabel.text = "Purchased"
                            buyLabel.fontSize = 20
                            buyLabel.horizontalAlignmentMode = .center
                            buyLabel.position = CGPoint(x: 0, y: 0)
                        }
                        boughtLabel.enumerateChildNodes(withName: "buyIcon") { (node, stop) in
                            node.removeFromParent()
                        }
                        enumerateChildNodes(withName: "label") { (node, stop) in
                            node.removeFromParent()
                        }
                        let newAmount = coins - (currentShip + 1) * (currentShip + 1) * 5
                        generateCoinLabel(coins: newAmount, scene: self)
                        let newCurrentShip = currentShip + 1
                        UserDefaults.standard.set(newAmount, forKey: "savedCoins")
                        UserDefaults.standard.set(newCurrentShip, forKey: "ship")
                        run(SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.run { [self] in
                            addChild(boughtLabel)
                        }]))
                        explosion(position: boughtLabel.position, scene: self, size: 0.05)
                        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (_) in
                            let gameScene = GameScene(size: self.view!.bounds.size)
                            gameScene.scaleMode = .resizeFill
                            let animation = SKTransition.fade(withDuration: 1.0)
                            self.view?.presentScene(gameScene, transition: animation)
                        }
                    } 
                }
            }
        }
    }
}
