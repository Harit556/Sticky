import SpriteKit

class ConfettiScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        view.allowsTransparency = true
    }

    /// Trigger confetti converting from SwiftUI coordinates (origin top-left) to SpriteKit (origin bottom-left)
    func triggerConfetti(at point: CGPoint) {
        let skPoint = CGPoint(x: point.x, y: size.height - point.y)
        triggerConfettiDirect(at: skPoint)
    }

    /// Trigger confetti at a point already in SpriteKit coordinates (origin bottom-left)
    func triggerConfettiDirect(at point: CGPoint) {
        let emitter = ConfettiEmitter.make()
        emitter.position = point
        addChild(emitter)

        // Remove emitter after particles finish
        let wait = SKAction.wait(forDuration: 3.5)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }
}
