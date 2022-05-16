import SpriteKit

class Item: SKSpriteNode {
    
    let items = ["coin", "health", "insta_destroy", "heatsink"]
    var item: String? = nil
    
    init(sprite: SKSpriteNode, index: Int){
        super.init(texture: SKTexture(image: UIImage(named: "\(items[index]).png")!), color: .white, size: CGSize(width: 0, height: 0))
        self.item = items[index]
        self.zPosition = -1
        self.position = sprite.position
        let size = sprite.size.width / 2
        self.size = CGSize(width: size, height: size)
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.size.width / 2)
        self.physicsBody?.velocity = CGVector(dx: 0, dy: -200)
        self.physicsBody?.categoryBitMask = GameScene.PhysicsCategory.item
        self.physicsBody?.contactTestBitMask = GameScene.PhysicsCategory.ship
        self.physicsBody?.collisionBitMask = 0
        self.name = "item"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func follow(location: CGPoint?, speed: CGFloat) {
        self.physicsBody?.velocity = CGVector(dx: (location!.x - self.position.x) * speed, dy: (location!.y - self.position.y) * speed)
    }
    
}
