import SpriteKit

class Debris: SKSpriteNode {
    
    let debrisTextures = ["debris1.png", "debris2.png", "debris3.png"]
    var hitpoints = CGFloat(0)
    
    init(position: CGPoint, index: Int, size: CGSize){
        super.init(texture: SKTexture(imageNamed: debrisTextures[index]), color: .white, size: CGSize(width: size.width, height: size.height))
        self.position = position
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hit(damage: CGFloat) {
        self.hitpoints -= damage
        self.run(SKAction.repeat(SKAction.sequence([SKAction.fadeAlpha(by: -0.5, duration: 0.1), SKAction.fadeAlpha(by: 0.5, duration: 0.1)]), count: 3))
    }
}
