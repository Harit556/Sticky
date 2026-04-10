import SpriteKit
import AppKit

class ConfettiScene: SKScene, SKPhysicsContactDelegate {

    private static let confettiCategory: UInt32 = 0x1
    private static let floorCategory: UInt32    = 0x2
    private static let maxNodes = 400

    private var fadeTimer: Timer?
    private var freezeTimer: Timer?
    private var textureCache: [String: SKTexture] = [:]

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        view.allowsTransparency = true

        physicsWorld.contactDelegate = self
        physicsWorld.speed = 1.0
        applyGravity()

        let floor = SKNode()
        floor.name = "floor"
        floor.position = CGPoint(x: size.width / 2, y: 0)
        floor.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 3, height: 1))
        floor.physicsBody?.isDynamic = false
        floor.physicsBody?.categoryBitMask = ConfettiScene.floorCategory
        floor.physicsBody?.restitution = 0.2
        floor.physicsBody?.friction = 0.8
        addChild(floor)

        freezeTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.freezeSettledNodes()
        }
    }

    @MainActor
    func applyGravity(_ gravity: ConfettiGravity? = nil) {
        let g = (gravity ?? ConfettiSettings.shared.gravity).yGravity
        physicsWorld.gravity = CGVector(dx: 0, dy: g)
    }

    @MainActor
    func triggerConfettiDirect(
        at point: CGPoint,
        size: ConfettiSize? = nil,
        amount: ConfettiAmount? = nil,
        gravity: ConfettiGravity? = nil,
        colorScheme: ConfettiColorScheme? = nil,
        style: ConfettiStyle? = nil
    ) {
        let defaults  = ConfettiSettings.shared
        let colors    = (colorScheme ?? defaults.colorScheme).colors
        let count     = (amount ?? defaults.amount).particleCount
        let texSize   = (size ?? defaults.size).textureSize
        let scale     = (size ?? defaults.size).particleScale
        let theStyle  = style ?? defaults.style

        applyGravity(gravity)
        evictIfNeeded(incoming: count)

        switch theStyle {
        case .classic: spawnClassic(at: point, colors: colors, texSize: texSize, scale: scale, count: count)
        case .burst:   spawnBurst(at: point, colors: colors, texSize: texSize, scale: scale, count: count)
        case .stars:   spawnStars(at: point, colors: colors, scale: scale, count: count)
        case .emoji:   spawnEmoji(at: point)
        case .minimal: spawnMinimal(at: point, colors: colors)
        }

        scheduleFade()
    }

    // MARK: - Style: Classic (original streaming rectangles)

    private func spawnClassic(at point: CGPoint, colors: [NSColor], texSize: CGSize, scale: CGFloat, count: Int) {
        for _ in 0..<count {
            let node = makeRect(texSize: texSize, scale: scale, color: colors.randomElement()!)
            node.position = CGPoint(x: point.x + .random(in: -15...15),
                                    y: point.y + .random(in: -8...8))
            let angle = CGFloat.random(in: .pi * 0.2 ... .pi * 0.8)
            let speed = CGFloat.random(in: 250...550)
            node.physicsBody?.velocity = CGVector(dx: cos(angle) * speed * (Bool.random() ? 1 : -1),
                                                   dy: sin(angle) * speed)
            node.physicsBody?.angularVelocity = .random(in: -10...10)
            addChild(node)
        }
    }

    // MARK: - Style: Burst (radial explosion from a single point)

    private func spawnBurst(at point: CGPoint, colors: [NSColor], texSize: CGSize, scale: CGFloat, count: Int) {
        let burstScale = scale * 1.1
        for i in 0..<count {
            let node = makeRect(texSize: texSize, scale: burstScale, color: colors.randomElement()!)
            node.position = point
            // Evenly spread angles with a bit of randomness
            let baseAngle = (CGFloat(i) / CGFloat(count)) * .pi * 2
            let angle = baseAngle + .random(in: -.pi / CGFloat(count) ... .pi / CGFloat(count))
            let speed = CGFloat.random(in: 300...700)
            node.physicsBody?.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
            node.physicsBody?.angularVelocity = .random(in: -12...12)
            addChild(node)
        }
    }

    // MARK: - Style: Stars (5-pointed star shapes)

    private func spawnStars(at point: CGPoint, colors: [NSColor], scale: CGFloat, count: Int) {
        for _ in 0..<count {
            let node = makeStar(scale: scale, color: colors.randomElement()!)
            node.position = CGPoint(x: point.x + .random(in: -20...20),
                                    y: point.y + .random(in: -10...10))
            let angle = CGFloat.random(in: .pi * 0.15 ... .pi * 0.85)
            let speed = CGFloat.random(in: 200...500)
            node.physicsBody?.velocity = CGVector(dx: cos(angle) * speed * (Bool.random() ? 1 : -1),
                                                   dy: sin(angle) * speed)
            node.physicsBody?.angularVelocity = .random(in: -8...8)
            addChild(node)
        }
    }

    // MARK: - Style: Emoji (animated emoji pop, no physics)

    private let celebrationEmoji = ["🎉", "✨", "🌟", "🎊", "💫", "⭐️", "🥳", "🎈"]

    private func spawnEmoji(at point: CGPoint) {
        let count = Int.random(in: 4...7)
        for i in 0..<count {
            let label = SKLabelNode(text: celebrationEmoji.randomElement()!)
            label.name = "confetti"
            label.fontSize = CGFloat.random(in: 28...48)
            label.position = CGPoint(x: point.x + .random(in: -60...60),
                                     y: point.y + .random(in: -20...20))
            label.setScale(0)
            label.zPosition = 10
            addChild(label)

            let delay    = SKAction.wait(forDuration: Double(i) * 0.08)
            let popIn    = SKAction.scale(to: 1.0, duration: 0.18)
            popIn.timingMode = .easeOut
            let floatUp  = SKAction.moveBy(x: .random(in: -30...30), y: .random(in: 60...140), duration: 1.2)
            floatUp.timingMode = .easeIn
            let fadeOut  = SKAction.fadeOut(withDuration: 0.5)
            let remove   = SKAction.removeFromParent()

            label.run(SKAction.sequence([
                delay,
                SKAction.group([popIn, SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.group([floatUp, fadeOut])
                ])]),
                remove
            ]))
        }
    }

    // MARK: - Style: Minimal (3–5 large slow pieces)

    private func spawnMinimal(at point: CGPoint, colors: [NSColor]) {
        let count = Int.random(in: 3...5)
        let bigTexSize = CGSize(width: 16, height: 10)
        let bigScale: CGFloat = 2.5
        for _ in 0..<count {
            let node = makeRect(texSize: bigTexSize, scale: bigScale, color: colors.randomElement()!)
            node.position = CGPoint(x: point.x + .random(in: -40...40),
                                    y: point.y + .random(in: -5...5))
            let angle = CGFloat.random(in: .pi * 0.3 ... .pi * 0.7)
            let speed = CGFloat.random(in: 80...180)
            node.physicsBody?.velocity = CGVector(dx: cos(angle) * speed * (Bool.random() ? 1 : -1),
                                                   dy: sin(angle) * speed)
            node.physicsBody?.angularVelocity = .random(in: -3...3)
            node.physicsBody?.linearDamping = 0.7
            addChild(node)
        }
    }

    // MARK: - Node factories

    private func makeRect(texSize: CGSize, scale: CGFloat, color: NSColor) -> SKSpriteNode {
        let key = "rect_\(color.hashValue)_\(Int(texSize.width))x\(Int(texSize.height))"
        let tex = textureCache[key] ?? {
            let img = NSImage(size: texSize, flipped: false) { rect in
                color.setFill()
                NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
                return true
            }
            let t = SKTexture(image: img)
            textureCache[key] = t
            return t
        }()

        let node = SKSpriteNode(texture: tex)
        node.name = "confetti"
        node.setScale(scale * .random(in: 0.6...1.4))
        node.zRotation = .random(in: 0 ... .pi * 2)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: texSize.width * scale * 0.8,
                                                      height: texSize.height * scale * 0.8))
        body.categoryBitMask    = ConfettiScene.confettiCategory
        body.collisionBitMask   = ConfettiScene.floorCategory
        body.contactTestBitMask = 0
        body.restitution        = .random(in: 0.1...0.4)
        body.friction           = 0.5
        body.linearDamping      = 0.4
        body.angularDamping     = 0.6
        body.mass               = 0.01
        node.physicsBody = body
        return node
    }

    private func makeStar(scale: CGFloat, color: NSColor) -> SKSpriteNode {
        let baseSize: CGFloat = 14 * scale
        let texSize = CGSize(width: baseSize, height: baseSize)
        let key = "star_\(color.hashValue)_\(Int(baseSize))"
        let tex = textureCache[key] ?? {
            let img = NSImage(size: texSize, flipped: false) { rect in
                color.setFill()
                Self.starPath(in: rect).fill()
                return true
            }
            let t = SKTexture(image: img)
            textureCache[key] = t
            return t
        }()

        let node = SKSpriteNode(texture: tex)
        node.name = "confetti"
        node.setScale(.random(in: 0.7...1.3))
        node.zRotation = .random(in: 0 ... .pi * 2)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: baseSize * 0.7, height: baseSize * 0.7))
        body.categoryBitMask    = ConfettiScene.confettiCategory
        body.collisionBitMask   = ConfettiScene.floorCategory
        body.contactTestBitMask = 0
        body.restitution        = .random(in: 0.1...0.5)
        body.friction           = 0.4
        body.linearDamping      = 0.35
        body.angularDamping     = 0.5
        body.mass               = 0.008
        node.physicsBody = body
        return node
    }

    private static func starPath(in rect: CGRect) -> NSBezierPath {
        let path = NSBezierPath()
        let cx = rect.midX, cy = rect.midY
        let outer = min(rect.width, rect.height) / 2 * 0.9
        let inner = outer * 0.42
        for i in 0..<10 {
            let angle = CGFloat(i) * .pi / 5 - .pi / 2
            let r = i % 2 == 0 ? outer : inner
            let pt = CGPoint(x: cx + cos(angle) * r, y: cy + sin(angle) * r)
            i == 0 ? path.move(to: pt) : path.line(to: pt)
        }
        path.close()
        return path
    }

    // MARK: - Performance

    private func evictIfNeeded(incoming: Int) {
        let nodes = children.filter { $0.name == "confetti" }
        let overflow = nodes.count + incoming - ConfettiScene.maxNodes
        guard overflow > 0 else { return }
        for i in 0..<min(overflow, nodes.count) { nodes[i].removeFromParent() }
    }

    private func freezeSettledNodes() {
        for child in children where child.name == "confetti" {
            guard let body = child.physicsBody, body.isDynamic else { continue }
            let speed = hypot(body.velocity.dx, body.velocity.dy)
            if speed < 8 && child.position.y < 60 { body.isDynamic = false }
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
        let nodes = children.filter { $0.name == "confetti" }
        guard !nodes.isEmpty else { return }
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove  = SKAction.removeFromParent()
        let seq     = SKAction.sequence([fadeOut, remove])
        for node in nodes {
            let delay = SKAction.wait(forDuration: .random(in: 0...0.2))
            node.run(SKAction.sequence([delay, seq]))
        }
    }

    // Legacy entry point kept for compatibility
    @MainActor
    func triggerConfetti(at point: CGPoint) {
        let skPoint = CGPoint(x: point.x, y: size.height - point.y)
        triggerConfettiDirect(at: skPoint)
    }
}
