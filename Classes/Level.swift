import SpriteKit

class Level: SKNode {
    
    let spawnDelay = "spawnDelay"
    var level = 0
    var debrisCount = 0
    var enemyCount = 0
    
    func generateLevel(scene: SKScene) {
        print("level: \(level)")
        debrisCount = (level + 4) * 3
        enemyCount = level * 2
        var i = 0
        var timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [self, scene] t in
            generateDebris(scene: scene)
            i += 1
            if i >= level + 4 {
                t.invalidate()
            }
        }
        var j = 0
        var timer2 = Timer.scheduledTimer(withTimeInterval: 6.5 - (Double(level) / 2), repeats: true) { [self, scene] t in
            generateEnemy(scene: scene, instance: j)
            j += 1
            if j >= level * 2{
                t.invalidate()
            }
        }
    }
    
    func generateDebris(scene: SKScene) {
        //randomize spawn
        var invert = CGFloat(0)
        if Int.random(in: 1...2) == 2 {
            invert = -1.0
        } else {
            invert = 1.0
        }
        let x = CGFloat.random(in: scene.frame.minX + 100...scene.frame.maxX - 100)
        let y = scene.frame.maxY + 50
        //get debris size relative to view
        let size = CGFloat.random(in: 50...60)
        //initalize debris
        let debris = Debris(position: CGPoint(x: x, y: y), index: Int.random(in: 0..<3), size: CGSize(width: size, height: size))
        debris.hitpoints = 2
        debris.physicsBody = SKPhysicsBody(circleOfRadius: size / 2)
        debris.physicsBody!.categoryBitMask = GameScene.PhysicsCategory.projectile
        debris.physicsBody!.contactTestBitMask = GameScene.PhysicsCategory.projectile
        debris.physicsBody!.collisionBitMask = 0
        debris.physicsBody?.velocity = CGVector(dx: 10 * invert, dy: -CGFloat.random(in: 200...250))
        debris.physicsBody?.angularVelocity = CGFloat.random(in: -3.0...3.0)
        debris.physicsBody?.linearDamping = 0.75
        debris.physicsBody?.angularDamping = 0
        debris.zPosition = -1
        debris.position = CGPoint(x: x, y: y)
        debris.name = "debris"
        scene.addChild(debris)
    }
    
    func generateChunks(debris: Debris, scene: SKScene) {
        var velocity = CGFloat(1)
        for _ in 0..<2 {
            let size = CGFloat.random(in: 25...30)
            let chunk = Debris(position: debris.position, index: Int.random(in: 0..<3), size: CGSize(width: size, height: size))
            chunk.hitpoints = 2
            chunk.name = "debris"
            chunk.physicsBody = SKPhysicsBody(circleOfRadius: size / 2)
            chunk.physicsBody!.categoryBitMask = GameScene.PhysicsCategory.projectile
            chunk.physicsBody!.contactTestBitMask = GameScene.PhysicsCategory.projectile
            chunk.physicsBody?.collisionBitMask = 0
            chunk.physicsBody?.linearDamping = 0.75
            chunk.physicsBody?.angularDamping = 0
            chunk.physicsBody?.velocity = CGVector(dx: 30 * velocity, dy: -50)
            chunk.physicsBody?.angularVelocity = debris.physicsBody!.angularVelocity
            chunk.physicsBody?.affectedByGravity = false
            scene.addChild(chunk)
            velocity *= -1
        }
    }
    
    func generateEnemy(scene: SKScene, instance: Int) {
        let x = CGFloat.random(in: scene.frame.minX...scene.frame.maxX)
        let y = scene.frame.maxY + 50
        let size = relativeSize(scene: scene)
        let enemy = Ship(position: CGPoint(x: x, y: y), texture: "enemy", hitpoints: 3)
        enemy.size = CGSize(width: size, height: size)
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: size / 2)
        enemy.physicsBody?.categoryBitMask = GameScene.PhysicsCategory.ship
        enemy.physicsBody?.contactTestBitMask = GameScene.PhysicsCategory.projectile
        enemy.physicsBody?.collisionBitMask = GameScene.PhysicsCategory.ship
        enemy.physicsBody?.linearDamping = 0
        enemy.physicsBody?.angularVelocity = 0
        enemy.damage = 1
        enemy.hitpoints = 3 + CGFloat(level)
        enemy.reload = 1.0
        enemy.name = "enemy\(instance)"
        scene.addChild(enemy)
        enemy.addChild(trail(isEnemy: true, scene: scene))
        enemy.generateHealthbar()
        scene.addChild(enemy.healthbar!)
    }
    
}
