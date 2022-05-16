import SwiftUI
import SpriteKit

struct ContentView: View {
    
    // Check if keys exist and set their default value
    // Create scene
    var scene: GameScene {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        return scene
    }
    
    // Display GameScene
    // Geometry Reader to get the frame size
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }.edgesIgnoringSafeArea(.all)
    }
    
}
