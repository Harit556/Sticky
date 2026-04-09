import SpriteKit
import AppKit

class ConfettiScene: SKScene, SKPhysicsContactDelegate {

    private static let confettiCategory: UInt32 = 0x1
    private static let floorCategory: UInt32 = 0x2

    /// Hard cap — if we exceed this, oldest confetti is removed before spawning more.
    private static let maxNodes = 400

    private var fadeTimer: Timer?
    private var freezeTimer: Timer?

    // Shared textures to avoid re-creating images every burst
    private var textureCache: [String: SKTexture] = [:]

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        view.allowsTransparency = true

        physicsWorld.contactDelegate = self
        physicsWorld.speed = 1.0
        applyGravity()

        // Floor boundary
        let floor = SKNode()
        floor.name = "floor"
        floor.position = CGPoint(x: size.width / 2, y: 0)
        floor.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 3, height: 1))
        floor.physicsBody?.isDynamic = false
        floor.physicsBody?.categoryBitMask = ConfettiScene.floorCategory
        floor.physicsBody?.restitution = 0.2
        floor.physicsBody?.friction = 0.8
        addChild(floor)

        // Periodically freeze settled confetti to save physics cycles
        freezeTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.freezeSettledNodes()
        }
    }

    @MainActor
    func applyGravity() {
        let g = ConfettiSettings.shared.gravity.yGravity
        physicsWorld.gravity = CGVector(dx: 0, dy: g)
    }

    @MainActor
    func triggerConfettiDirect(at point: CGPoint) {
        applyGravity()

        let settings = ConfettiSettings.shared
        let colors = settings.colorScheme.colors
        let count = settings.amount.particleCount
        let texSize = settings.size.textureSize
        let scale = settings.size.particleScale

        // Evict oldest confetti if we'd exceed the cap
        evictIfNeeded(incoming: count)

        for _ in 0..<count {
            let color = colors[Int.random(in: 0..<colors.count)]
            let node = makeConfettiPiece(size: texSize, scale: scale, color: color)
            node.position = CGPoint(
                x: point.x + CGFloat.random(in: -15...15),
                y: point.y + CGFloat.random(in: -8...8)
            )

            let angle = CGFloat.random(in: CGFloat.pi * 0.2 ... CGFloat.pi * 0.8)
            let speed = CGFloat.random(in: 250...550)
            node.physicsBody?.velocity = CGVector(
                dx: cos(angle) * speed * (Bool.random() ? 1 : -1),
                dy: sin(angle) * speed
            )
            node.physicsBody?.angularVelocity = CGFloat.random(in: -10...10)

            addChild(node)
        }

        scheduleFade()
    }

    @MainActor
    func triggerConfetti(at point: CGPoint) {
        let skPoint = CGPoint(x: point.x, y: size.height - point.y)
        triggerConfettiDirect(at: skPoint)
    }

    // MARK: - Node creation

    private func texture(for color: NSColor, size texSize: CGSize) -> SKTexture {
        let key = "\(color.hashValue)_\(Int(texSize.width))x\(Int(texSize.height))"
        if let cached = textureCache[key] { return cached }
        let image = NSImage(size: texSize, flipped: false) { rect in
            color.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
            return true
        }
        let tex = SKTexture(image: image)
        textureCache[key] = tex
        return tex
    }

    private func makeConfettiPiece(size texSize: CGSize, scale: CGFloat, color: NSColor) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture(for: color, size: texSize))
        node.name = "confetti"
        node.setScale(scale * CGFloat.random(in: 0.6...1.4))
        node.zRotation = CGFloat.random(in: 0 ... .pi * 2)

        let body = SKPhysicsBody(rectangleOf: CGSize(
            width: texSize.width * scale * 0.8,
            height: texSize.height * scale * 0.8
        ))
        body.categoryBitMask = ConfettiScene.confettiCategory
        // Only collide with the floor — NOT with other confetti.
        // Confetti-to-confetti collision is O(n²) and the main cause of lag.
        body.collisionBitMask = ConfettiScene.floorCategory
        body.contactTestBitMask = 0
        body.restitution = CGFloat.random(in: 0.1...0.4)
        body.friction = 0.5
        body.linearDamping = 0.4
        body.angularDamping = 0.6
        body.mass = 0.01
        node.physicsBody = body

        return node
    }

    // MARK: - Performance management

    /// Remove oldest confetti to stay under the node cap.
    private func evictIfNeeded(incoming: Int) {
        let confettiNodes = children.filter { $0.name == "confetti" }
        let overflow = confettiNodes.count + incoming - ConfettiScene.maxNodes
        guard overflow > 0 else { return }

        // Remove the oldest (first added) nodes instantly
        for i in 0..<min(overflow, confettiNodes.count) {
            confettiNodes[i].removeFromParent()
        }
    }

    /// Freeze confetti that has come to rest — removes them from the physics simulation
    /// so they just sit there as static sprites at zero CPU cost.
    private func freezeSettledNodes() {
        for child in children where child.name == "confetti" {
            guard let body = child.physicsBody, body.isDynamic else { continue }
            let speed = hypot(body.velocity.dx, body.velocity.dy)
            // If nearly stationary and near the floor, freeze it
            if speed < 8 && child.position.y < 60 {
                body.isDynamic = false
            }
        }
    }

    // MARK: - Cleanup

    private func scheduleFade() {
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.fadeOutConfetti()
        }
    }

    private func fadeOutConfetti() {
        let confettiNodes = children.filter { $0.name == "confetti" }
        guard !confettiNodes.isEmpty else { return }

        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let seq = SKAction.sequence([fadeOut, remove])

        for node in confettiNodes {
            let delay = SKAction.wait(forDuration: Double.random(in: 0...0.2))
            node.run(SKAction.sequence([delay, seq]))
        }
    }
}
