import SpriteKit

class Ship: SKSpriteNode {
    
    var image: String? = nil
    var hitpoints = CGFloat(3)
    var healthbar: SKSpriteNode? = nil
    var damage = CGFloat(1)
    var reload = CGFloat(2)
    let lockBlaster = "lockBlaster"
    
    init(position: CGPoint, texture: String, hitpoints: CGFloat){
        super.init(texture: SKTexture(image: UIImage(named: "\(texture).png")!), color: .white, size: CGSize(width: 0, height: 0))
        //player settings
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.image = texture
        self.position = position
        self.hitpoints = hitpoints
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //Adjust the ship size relative to the view
    func adjustBody(scene: SKScene) {
        let size = relativeSize(scene: scene) * 1.5
        self.size = CGSize(width: size, height: size)
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size) 
        self.physicsBody?.categoryBitMask = GameScene.PhysicsCategory.ship
        self.physicsBody?.contactTestBitMask = GameScene.PhysicsCategory.projectile
        self.physicsBody?.collisionBitMask = 0
        self.position = CGPoint(x: frame.midX, y: frame.midY)
    }
    
    //Fire blasters
    func fire(isEnemy: Bool, scene: SKNode, speed: CGFloat) {
        let blaster = Blaster(texture: "blue.png")
        if isEnemy {
            blaster.name = "enemyBlaster"
            blaster.texture = SKTexture(imageNamed: "red.png")
        } else {
            blaster.name = "blaster"
        }
        guard self.action(forKey: lockBlaster) == nil else {
            return
        }
        let angle = self.zRotation + (Double.pi / 2)
        blaster.zPosition = -1
        blaster.position = self.position
        let vector = CGVector(dx: cos(angle) * 1500, dy: sin(angle) * 1500)
        blaster.run(SKAction.move(by: vector, duration: speed))
        run(SKAction.wait(forDuration: reload), withKey: lockBlaster)
        run(SKAction.playSoundFileNamed("\(blaster.name!)_sound.wav", waitForCompletion: false))
        scene.addChild(blaster)
        blaster.run(SKAction.sequence([SKAction.wait(forDuration: 2.0), SKAction.removeFromParent()]))
    }
    
    func heatsink(scene: SKNode, location: CGPoint) {
        let blaster = Blaster(texture: "blue.png")
        guard self.action(forKey: lockBlaster) == nil else {
            return
        }
        blaster.physicsBody?.velocity = CGVector(dx: (location.x - blaster.position.x) * speed, dy: (location.y - blaster.position.y) * 5)
        run(SKAction.wait(forDuration: reload), withKey: lockBlaster)
        run(SKAction.playSoundFileNamed("\(blaster.name!)_sound.wav", waitForCompletion: false))
        scene.addChild(blaster)
        blaster.run(SKAction.sequence([SKAction.wait(forDuration: 2.0), SKAction.removeFromParent()]))
    }
    
    func generateHealthbar() {
        //get ship name
        let name = self.name!
        enumerateChildNodes(withName: "\(name)_healthbar") { (node, stop) in
            node.removeFromParent()
        }
        //healthbar
        healthbar = SKSpriteNode(imageNamed: "healthbar")
        let height = self.size.width / 8
        let width = (self.size.width / 5) * self.hitpoints
        healthbar!.size = CGSize(width: width, height: height)
        healthbar!.anchorPoint = CGPoint(x: 0.5, y: 6)
        healthbar!.position = self.position
        healthbar!.name = "\(name)_healthbar"
    }
    
    //Hit animation
    func hit(damage: CGFloat) {
        self.hitpoints -= damage
        self.run(SKAction.repeat(SKAction.sequence([SKAction.fadeAlpha(by: -0.5, duration: 0.1), SKAction.fadeAlpha(by: 0.5, duration: 0.1)]), count: 3))
    }
    
    //Follow location
    func follow(location: CGPoint?, speed: CGFloat) {
        self.physicsBody?.velocity = CGVector(dx: (location!.x - self.position.x) * speed, dy: (location!.y - self.position.y) * speed)
    }
    
    //Respawn player with temporary invincibility
    func respawn(scene: SKScene) {
        scene.addChild(self)
        self.run(SKAction.sequence([SKAction.run { [self] in
            self.physicsBody?.contactTestBitMask = 0
            self.position = CGPoint(x: 0, y: self.position.y)
            self.zRotation = 0
            self.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        }, SKAction.repeat(SKAction.sequence([SKAction.fadeAlpha(by: -0.5, duration: 0.1), SKAction.fadeAlpha(by: 0.5, duration: 0.1)]), count: 10), SKAction.run { [self] in
            self.physicsBody?.contactTestBitMask = GameScene.PhysicsCategory.projectile
            }]))
    }
    
    //Turn enemy towards player with delay
    func turn(location: CGPoint?) {
        let angle = atan2(location!.y - self.position.y, location!.x - self.position.x)
        self.run(SKAction.rotate(toAngle: angle - (Double.pi/2), duration: 0.2, shortestUnitArc: true))
    }
    
}
