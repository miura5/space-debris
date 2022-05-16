//Things to add: ship upgrades, health bars, camera shake, power-ups

import SwiftUI
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let all: UInt32 = UInt32.max
        static let ship: UInt32 = 0b1
        static let projectile: UInt32 = 0b10
        static let item: UInt32 = 0b100
    }
    
    var currentShip = UserDefaults.standard.integer(forKey: "ship")
    var level = Level()
    var player = Ship(position: CGPoint(x: 0, y: 0), texture: "player0", hitpoints: 3)
    var powered = false
    var heatsink = false
    var lives = 0
    var touchLocation: CGPoint? = nil
    var coins = UserDefaults.standard.integer(forKey: "savedCoins")
    var highscore = UserDefaults.standard.integer(forKey: "highscore")
    var score = 0
    
    override func didMove(to view: SKView) {
        
        let size = relativeSize(scene: self)
        
        // Background Music
        
        let backgroundMusic = SKAudioNode(fileNamed: "space_theme.mp3")
        addChild(backgroundMusic)
        
        // Create physics body and contact
        
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsBody = SKPhysicsBody()
        physicsWorld.contactDelegate = self
        backgroundColor = .black
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        // Random stars background
        
        generateBackground(scene: self, size: 1, speed: 400)
        generateBackground(scene: self, size: 1.5, speed: 440)
        
        // Default player settings
        
        player.texture = SKTexture(imageNamed: "player\(currentShip)")
        player.adjustBody(scene: self)
        player.position = CGPoint(x: 0, y: -200)
        player.name = "player"
        addChild(player)
        player.damage = 1
        player.reload = 0.5 / (CGFloat(currentShip) + 1)
        let trail1 = trail(isEnemy: false, scene: self)
        trail1.position.x -= size * 0.2
        let trail2 = trail(isEnemy: false, scene: self)
        trail2.position.x += size * 0.2
        player.addChild(trail1)
        player.addChild(trail2)
        player.generateHealthbar()
        
        let animation1 = SKAction.moveBy(x: 0, y: 100, duration: 2.0)
        animation1.timingMode = .easeInEaseOut
        let animation2 = SKAction.moveBy(x: 0, y: -100, duration: 2.0)
        animation2.timingMode = .easeInEaseOut
        player.run(SKAction.repeatForever(SKAction.sequence([animation1, animation2])))
        
        // Display UI depending on if the game is started (player has lives)
        
        let shopLabel = SKSpriteNode(imageNamed: "shop.png")
        shopLabel.size = CGSize(width: size, height: size)
        shopLabel.position = CGPoint(x: frame.minX + size, y: frame.minY + size)
        shopLabel.name = "shop"
        addChild(shopLabel)
        if lives > 0 {
            updateLabels()
            generateLifeLabel(lives: lives, scene: self, currentShip: currentShip)
            addChild(player.healthbar!)
        } else {
            generateTitleLabel(scene: self, title: "space debris", subtitle: "tap to start. drag to play.")
            let highscoreLabel = generateValueLabel(value: highscore, scene: self)
            highscoreLabel.position = CGPoint(x: 0, y: frame.maxY - size)
            addChild(highscoreLabel)
            generateCoinLabel(coins: coins, scene: self)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            
            // If player touches anywhere other than the shop button, start game
            
            if lives == 0 {
                let gameScene = GameScene(size: self.view!.bounds.size)
                gameScene.scaleMode = .aspectFill
                gameScene.lives = 3
                let animation = SKTransition.fade(withDuration: 1.0)
                self.view?.presentScene(gameScene, transition: animation)
            }
            let touchedNode = nodes(at: touch.location(in: self))
            for node in touchedNode {
                if node.name == "shop" {
                    saveProgress()
                    let shopScene = ShopScene(size: self.view!.bounds.size)
                    shopScene.scaleMode = .aspectFill
                    let animation = SKTransition.fade(withDuration: 1.0)
                    self.view?.presentScene(shopScene, transition: animation)
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Player follows drag gestures and fires
        
        if lives > 0 {
            for touch in touches {
                touchLocation = touch.location(in: self)
                let angle = atan2(touchLocation!.x - player.position.x, touchLocation!.y - player.position.y)
                player.run(SKAction.rotate(toAngle: -angle, duration: 1.0))
                player.fire(isEnemy: false, scene: self, speed: 1)
                player.follow(location: CGPoint(x: touchLocation!.x, y: player.position.y), speed: 4)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Set location to nil so the ship drifts
        
        touchLocation = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        // Wrap position of player
        
        checkPosition(sprite: player, scene: self)
        
        // Get all enemy instances in a level and update their behavior and healthbar
        
        for i in 0..<level.level * 2 {
            enumerateChildNodes(withName: "enemy\(i)") { [self] (node, stop) in
                let enemy = node as! Ship
                enemy.follow(location: CGPoint(x: player.position.x, y: player.position.y + 400), speed: 1.5)
                enemy.turn(location: player.position)
                enemy.fire(isEnemy: true, scene: self, speed: 3)
                // Enemy healthbar follows enemy
                if enemy.healthbar != nil {
                    enemy.healthbar!.position = enemy.position
                }
                if heatsink && level.enemyCount > 0 {
                    enumerateChildNodes(withName: "blaster") { [self] (node, stop) in
                        let blaster = node as! Blaster
                        blaster.run(SKAction.move(to: enemy.position, duration: 0.3))
                    }
                }
            }
        }
        
        // Player healthbar follows player
        
        player.healthbar!.position = player.position
        
        // If level is ongoing, wrap the position of debris and items
        // If all debris and enemies are destroyed, start the next level
        
        if level.debrisCount > 0 || level.enemyCount > 0 {
            enumerateChildNodes(withName: "debris") { [self] (node, stop) in
                let debris = node as! Debris
                checkPosition(sprite: debris, scene: self)
                if heatsink && level.enemyCount == 0 && level.debrisCount > 0 {
                    enumerateChildNodes(withName: "blaster") { [self] (node, stop) in
                        let blaster = node as! Blaster
                        blaster.run(SKAction.move(to: debris.position, duration: 0.3))
                    }
                }
            }
            enumerateChildNodes(withName: "item") { [self] (node, stop) in
                let items = node as! Item
                checkPosition(sprite: items, scene: self)
                items.follow(location: player.position, speed: 2)
            }
        } else if level.debrisCount <= 0 && level.enemyCount <= 0 && lives > 0 {
            level.level += 1
            level.generateLevel(scene: self)
        }
    }
    
    //Define possible collisions
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstNode = contact.bodyA.node
        let secondNode = contact.bodyB.node
        
        if firstNode == nil || secondNode == nil {
            return
        }
        else if firstNode?.name == "player" && secondNode?.name == "debris" || secondNode?.name == "enemyBlaster" {
            collisionBetween(object: firstNode!, object2: secondNode!)
        } else if secondNode?.name == "player" && firstNode?.name == "debris" || firstNode?.name == "enemyBlaster" {
            collisionBetween(object: secondNode!, object2: firstNode!)
        } else if firstNode?.name == "item" && secondNode?.name == "player" {
            collisionBetween(object: firstNode!, object2: secondNode!)
        } else if secondNode?.name == "item" && firstNode?.name == "player" {
            collisionBetween(object: secondNode!, object2: firstNode!)
        } else if firstNode?.name == "blaster" && secondNode?.name == "debris" {
            collisionBetween(object: firstNode!, object2: secondNode!)
        } else if secondNode?.name == "blaster" && firstNode?.name == "debris" {
            collisionBetween(object: secondNode!, object2: firstNode!)
        } else if firstNode?.name == "blaster" && secondNode!.name!.contains("enemy") {
            collisionBetween(object: firstNode!, object2: secondNode!)
        } else if secondNode?.name == "blaster" && firstNode!.name!.contains("enemy") {
            collisionBetween(object: secondNode!, object2: firstNode!) 
        }
    }
    
    // Define collision behavior
    
    func collisionBetween(object: SKNode, object2: SKNode) {
        if object.name == "player" {
            if let player = object as? Ship {
                // If player collides with debris, decrease debris count depending on debris size and decrease player health
                
                if object2.name == "debris" {
                    player.hit(damage: 0.5)
                    if let debris = object2 as? Debris {
                        if debris.size.width >= 50 {
                            level.debrisCount -= 3
                            explosion(position: debris.position, scene: self, size: 0.01)
                            debris.removeFromParent()
                        } else {
                            level.debrisCount -= 1
                            explosion(position: debris.position, scene: self, size: 0.01)
                            debris.removeFromParent()
                        }
                        print(level.debrisCount)
                    } 
                } else { // Player collides with enemy blast and damaged
                    object2.removeFromParent()
                    player.hit(damage: 1)
                }
                
                // After taking damage, if player h.as no hitpoints and has lives remaining, respawn player. Otherwise, GAME OVER
                
                if player.hitpoints <= 0 && lives > 0 {
                    explosion(position: player.position, scene: self, size: 0.01)
                    run(SKAction.playSoundFileNamed("player_hit_sound.wav", waitForCompletion: false))
                    player.removeFromParent()
                    player.hitpoints = 3
                    lives -= 1
                    player.respawn(scene: self)
                }
                
                player.healthbar!.removeFromParent()
                player.generateHealthbar()
                addChild(player.healthbar!)
                updateLabels()
                
                if lives == 0 {
                    saveProgress()
                    explosion(position: player.position, scene: self, size: 0.01)
                    run(SKAction.playSoundFileNamed("player_hit_sound.wav", waitForCompletion: false))
                    player.healthbar!.removeFromParent()
                    player.removeFromParent()
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [self] _ in
                        let gameScene = GameScene(size: self.view!.bounds.size)
                        gameScene.scaleMode = .resizeFill
                        gameScene.lives = 0
                        let animation = SKTransition.fade(withDuration: 0.5)
                        self.view?.presentScene(gameScene, transition: animation)
                    }
                }
            }
        } else if object.name == "item" { 
            if let item = object as? Item {
                if item.item == "health" {
                    run(SKAction.playSoundFileNamed("health_sound.wav", waitForCompletion: false))
                    object.removeFromParent()
                    if player.hitpoints < 3 {
                        player.hitpoints += 3
                        player.healthbar!.removeFromParent()
                        player.generateHealthbar()
                        addChild(player.healthbar!)
                    }
                } else if item.item == "coin" {
                    run(SKAction.playSoundFileNamed("coin_sound.wav", waitForCompletion: false))
                    object.removeFromParent()
                    coins += 1
                    updateLabels()
                    saveProgress()
                    if currentShip < 2 && coins == (currentShip + 1) * (currentShip + 1) * 5 {
                        generateUpgradeAvailableLabel(scene: self)
                    }
                } else if item.item == "insta_destroy" && !powered {
                    run(SKAction.playSoundFileNamed("power_sound.wav", waitForCompletion: false))
                    object.removeFromParent()
                    player.damage = 1000
                    powered = true
                    generateTimerLabel(image: "insta_destroy.png", time: 10, scene: self)
                    Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [self, player] (_) in
                        player.damage = 1
                        powered = false
                    }
                } else if item.item == "heatsink" && !powered {
                    run(SKAction.playSoundFileNamed("power_sound.wav", waitForCompletion: false))
                    object.removeFromParent()
                    powered = true
                    heatsink = true
                    generateTimerLabel(image: "heatsink.png", time: 20, scene: self)
                    Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { [self, player] (_) in
                        heatsink = false
                        powered = false
                    }
                }
            }
            
        } else if object.name == "blaster" && object2.name == "debris"  {
            if let debris = object2 as? Debris {
                debris.hit(damage: player.damage)
                object.removeFromParent()
                if debris.hitpoints <= 0 {
                    explosion(position: debris.position, scene: self, size: 0.01)
                    if debris.size.width >= 50 {
                        level.generateChunks(debris: debris, scene: self)
                        score += 100
                    } else {
                        score += 150
                        let coin = Item(sprite: debris, index: 0)
                        addChild(coin)
                        coin.addGlow(radius: 5)
                    }
                    level.debrisCount -= 1
                    debris.removeFromParent()
                    print(level.debrisCount)
                    updateLabels()
                    saveProgress()
                }
            }
        } else if object.name == "blaster" && object2.name!.contains("enemy") {
            if let enemy = object2 as? Ship {
                enemy.hit(damage: player.damage)
                enemy.healthbar!.removeFromParent()
                enemy.generateHealthbar()
                addChild(enemy.healthbar!)
                object.removeFromParent()
                if enemy.hitpoints <= 0 {
                    if Bool.random() && !powered{
                        let insta_destroy = Item(sprite: enemy, index: 2)
                        addChild(insta_destroy)
                        insta_destroy.addGlow(radius: 5)
                    } else if player.hitpoints < 3 {
                        let health = Item(sprite: enemy, index: 1)
                        addChild(health)
                        health.addGlow(radius: 5)
                    } else if !Bool.random() && !powered {
                        let heatsink = Item(sprite: enemy, index: 3)
                        addChild(heatsink)
                        heatsink.addGlow(radius: 5)
                    }
                    explosion(position: enemy.position, scene: self, size: 0.01)
                    enemy.removeFromParent()
                    level.enemyCount -= 1
                    enumerateChildNodes(withName: "\(enemy.name!)_healthbar") { (node, stop) in
                        node.removeFromParent()
                    }
                }
            }
        }
    }
    
    func updateLabels() {
        let offset = relativeSize(scene: self) / 2
        enumerateChildNodes(withName: "label") { (node, stop) in
            node.removeFromParent()
        }
        //    highscore label
        let highscoreLabel = generateValueLabel(value: highscore, scene: self)
        highscoreLabel.horizontalAlignmentMode = .center
        highscoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - offset * 2)
        addChild(highscoreLabel)
        //    current score label
        let scoreLabel = generateValueLabel(value: score, scene: self)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: frame.minX + offset, y: frame.maxY - offset * 2)
        addChild(scoreLabel)
        //    lives label
        generateLifeLabel(lives: lives, scene: self, currentShip: currentShip)
        //    coin label
        generateCoinLabel(coins: coins, scene: self)
    }
    
    func saveProgress() {
        if score > highscore {
            UserDefaults.standard.set(score, forKey: "highscore")
        }
        UserDefaults.standard.set(coins, forKey: "savedCoins")
    }
    
}
