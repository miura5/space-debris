import SpriteKit

let font = "AmericanTypewriter-Bold"

extension SKSpriteNode {
    func addGlow(radius: CGFloat) {
        let texture = SKSpriteNode(texture: self.texture, size: self.size)
        let glow = SKEffectNode()
        glow.addChild(texture)
        glow.alpha = 0.25
        glow.blendMode = .add
        glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": radius])
        glow.shouldRasterize = true
        addChild(glow)
        let fadeIn = SKAction.fadeAlpha(by: -0.2, duration: 0.5)
        fadeIn.timingMode = .easeInEaseOut
        let fadeOut = SKAction.fadeAlpha(by: 0.2, duration: 0.5)
        fadeOut.timingMode = .easeInEaseOut
        glow.run(SKAction.repeatForever(SKAction.sequence([fadeIn, fadeOut])))
    }
}

extension SKSpriteNode {
    func drawBorder(color: UIColor, width: CGFloat) {
        let border = SKShapeNode(rect: frame, cornerRadius: 10)
        border.fillColor = .clear
        border.strokeColor = color
        border.lineWidth = width
        addChild(border)
    }
}

func checkPosition(sprite: SKSpriteNode, scene: SKScene) {
    if (sprite.position.x < scene.frame.minX - 50) {
        sprite.position.x = scene.frame.maxX + 50
    } else if (sprite.position.x > scene.frame.maxX + 50) {
        sprite.position.x = scene.frame.minX - 50
    } else if (sprite.position.y < scene.frame.minY - 50) {
        sprite.position.y = scene.frame.maxY + 50
    } else if (sprite.position.y > scene.frame.maxY + 50) {
        sprite.position.y = scene.frame.minY - 50
    }
}


func explosion(position: CGPoint, scene: SKScene, size: CGFloat) {
    let size = relativeSize(scene: scene) * 0.09
    let emitter = SKEmitterNode()
    emitter.particleSize = CGSize(width: size, height: size)
    emitter.particleZPosition = 0
    emitter.numParticlesToEmit = 100
    emitter.particleBirthRate = 300
    emitter.particleLifetimeRange = 2
    emitter.emissionAngleRange = 360 * .pi / 180
    emitter.particleSpeed = 100
    emitter.particleColor = .white
    emitter.position = position
    emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: [SKColor.systemYellow, SKColor.systemOrange, SKColor.systemRed, SKColor.darkGray], times: [0, 0.25, 0.5, 1])
    scene.run(SKAction.playSoundFileNamed("explosion_sound.wav", waitForCompletion: false))
    scene.addChild(emitter)
}

func generateBackground(scene: SKNode, size: CGFloat, speed: CGFloat) {
    let stars = SKEmitterNode()
    let width = CGFloat.random(in: 1...2) * size
    stars.particleSize = CGSize(width: width, height: width)
    stars.particleZPosition = -1
    stars.particleBirthRate = 5
    stars.particleLifetime = 4
    stars.particleSpeed = -speed
    stars.particleRotationRange = 50
    stars.particleRotationSpeed = 1
    stars.targetNode = scene
    stars.particleColor = .white
    stars.position.y += scene.frame.maxY * 1.5
    stars.particlePositionRange = CGVector(dx: scene.frame.maxX - scene.frame.minX, dy: scene.frame.minY
    )
    scene.addChild(stars)
}

func generateValueLabel(value: Int, scene: SKScene) -> SKLabelNode {
    let size = relativeSize(scene: scene) / 2
    let label = SKLabelNode(text: "\(value)")
    label.fontSize = size
    label.fontName = font
    label.horizontalAlignmentMode = .center
    label.name = "label"
    return label
}

func generateTimerLabel(image: String, time: Int, scene: SKScene) {
    let imageLabel = SKSpriteNode(imageNamed: image)
    let size = relativeSize(scene: scene) / 2
    imageLabel.size = CGSize(width: size, height: size)
    imageLabel.position = CGPoint(x: 0, y: scene.frame.minY + size * 2)
    imageLabel.addGlow(radius: 5)
    var i = time
    var mins: Int = time / 60
    var tenths: Int = time % 60 / 10
    var seconds: Int = time % 60 % 10
    let timerLabel = SKLabelNode(text: "\(mins):\(tenths)\(seconds)")
    timerLabel.fontSize = size
    timerLabel.fontName = font
    timerLabel.position = CGPoint(x: 0, y: imageLabel.position.y - size * 1.5)
    scene.addChild(imageLabel)
    scene.addChild(timerLabel)
    let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [scene] t in
        i -= 1
        if i >= 60 {
            mins = i / 60
            tenths = i % 60 / 10
            seconds = i % 60 % 10
        } else if i >= 10 {
            mins = 0
            tenths = i / 10
            seconds = i % 10
        } else {
            mins = 0
            tenths = 0
            seconds = i
        }
        timerLabel.removeFromParent()
        timerLabel.text = "\(mins):\(tenths)\(seconds)"
        scene.addChild(timerLabel)
        if i <= 0 {
            timerLabel.removeFromParent()
            imageLabel.removeFromParent()
            t.invalidate()
        }
    }
}

func generateLifeLabel(lives: Int, scene: SKScene, currentShip: Int) {
    if lives == 0 {
        return
    }
    let size = relativeSize(scene: scene) / 2
    let offset = size * 1.1
    for i in 1 ... lives {
        let lifeLabel = SKSpriteNode(imageNamed: "player\(currentShip).png")
        lifeLabel.size = CGSize(width: size, height: size)
        lifeLabel.anchorPoint = CGPoint(x: 0, y: 0)
        lifeLabel.position = CGPoint(x: scene.frame.maxX - size - (offset * CGFloat(i)), y: scene.frame.maxY - size * 2)
        lifeLabel.name = "label"
        
        scene.addChild(lifeLabel)
    }
}

func generateCoinLabel(coins: Int, scene: SKScene) {
    let size = relativeSize(scene: scene)
    let imageLabel = SKSpriteNode(imageNamed: "coin.png")
    imageLabel.anchorPoint = CGPoint(x: -1, y: 0.5)
    imageLabel.size = CGSize(width: size / 2, height: size / 2)
    imageLabel.name = "label"
    imageLabel.addGlow(radius: 5)
    let textLabel = SKLabelNode(text: "\(coins)")
    textLabel.fontSize = size / 2
    textLabel.verticalAlignmentMode = .center
    textLabel.horizontalAlignmentMode = .center
    textLabel.position = CGPoint(x: scene.frame.maxX - size * 1.6, y: scene.frame.minY + size / 1.6)
    textLabel.name = "label"
    textLabel.fontName = font
    scene.addChild(textLabel)
    textLabel.addChild(imageLabel)
}

func generateTitleLabel(scene: SKScene, title: String, subtitle: String) {
    let titleLabel = SKLabelNode(text: title)
    titleLabel.fontSize = relativeSize(scene: scene) / 1.25
    titleLabel.fontName = font
    titleLabel.fontColor = .systemBlue
    titleLabel.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY + (titleLabel.fontSize / 3))
    titleLabel.horizontalAlignmentMode = .center
    titleLabel.verticalAlignmentMode = .center
    titleLabel.name = "label"
    scene.addChild(titleLabel)
    let subtitleLabel = SKLabelNode(text: subtitle)
    subtitleLabel.fontSize = titleLabel.fontSize / 2
    subtitleLabel.fontName = font
    subtitleLabel.fontColor = .white
    subtitleLabel.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY - (titleLabel.fontSize / 3))
    subtitleLabel.horizontalAlignmentMode = .center
    subtitleLabel.verticalAlignmentMode = .center
    subtitleLabel.name = "label"
    scene.addChild(subtitleLabel)
}

func generateUpgradeAvailableLabel(scene: SKScene) {
    let size = relativeSize(scene: scene)
    let upgradeAvailabeLabel = SKLabelNode(text: "ship upgrade available")
    upgradeAvailabeLabel.fontSize = size / 2
    upgradeAvailabeLabel.fontColor = .white
    upgradeAvailabeLabel.fontName = font
    upgradeAvailabeLabel.zPosition = 2
    let upgradeAvailabeSubtitle = SKLabelNode(text: "tap the hangar to upgrade")
    upgradeAvailabeSubtitle.fontSize = size / 2
    upgradeAvailabeSubtitle.fontColor = .white
    upgradeAvailabeSubtitle.fontName = font
    upgradeAvailabeLabel.addChild(upgradeAvailabeSubtitle)
    upgradeAvailabeSubtitle.position = CGPoint(x: 0, y: -size)
    upgradeAvailabeSubtitle.zPosition = 2
    let animation = SKAction.sequence([SKAction.fadeAlpha(by: -0.2, duration: 0.1), SKAction.fadeAlpha(by: 0.2, duration: 0.1)])
    scene.addChild(upgradeAvailabeLabel)
    upgradeAvailabeLabel.run(SKAction.repeatForever(animation))
    Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { (_) in
        upgradeAvailabeLabel.removeFromParent()
    }
}

func trail(isEnemy: Bool, scene: SKScene) -> SKNode {
    let size = relativeSize(scene: scene) * 0.04
    let emitter = SKEmitterNode()
    emitter.particleSize = CGSize(width: size, height: size)
    emitter.particleZPosition = -1
    emitter.particleBirthRate = 100
    emitter.particleLifetimeRange = 1
    emitter.emissionAngleRange = 0.2
    emitter.particleSpeed = -400
    emitter.particleColor = .white
    emitter.targetNode = scene
    if isEnemy{
        emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: [SKColor.systemRed, SKColor.red], times: [0, 0.5])
    } else {
        emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: [SKColor.systemCyan, SKColor.systemBlue, SKColor.systemIndigo, SKColor.lightGray], times: [0, 0.25, 0.75, 1.0])
    }
    emitter.position = (CGPoint(x: 0, y: -30))
    return emitter
}

func relativeSize(scene: SKScene) -> CGFloat{
    if scene.size.height > scene.size.width {
        return scene.size.height * 0.07
    } else {
        return scene.size.width * 0.07
    }
}

