import SpriteKit

class Blaster: SKSpriteNode {
    
    init(texture: String) {
        super.init(texture: SKTexture(image: UIImage(named: texture)!), color: .clear, size: CGSize(width: 10, height: 10))
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.size.width / 2)
        self.physicsBody!.categoryBitMask = GameScene.PhysicsCategory.projectile
        self.physicsBody!.contactTestBitMask = GameScene.PhysicsCategory.projectile
        self.physicsBody!.collisionBitMask = 0
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.isDynamic = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
