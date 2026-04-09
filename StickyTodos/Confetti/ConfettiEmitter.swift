import SpriteKit
import AppKit

enum ConfettiEmitter {
    static func make() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Texture: small colored rectangle
        let size = CGSize(width: 8, height: 5)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.white.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
            return true
        }
        emitter.particleTexture = SKTexture(image: image)

        // Emission — big burst
        emitter.particleBirthRate = 300
        emitter.numParticlesToEmit = 100
        emitter.emissionAngle = .pi / 2 // upward
        emitter.emissionAngleRange = .pi  // wide spread upward

        // Lifetime — longer so particles can fall down the screen
        emitter.particleLifetime = 3.0
        emitter.particleLifetimeRange = 1.0

        // Speed — launch upward and outward
        emitter.particleSpeed = 350
        emitter.particleSpeedRange = 200

        // Gravity — pulls confetti down the screen
        emitter.yAcceleration = -250

        // Horizontal drift for natural feel
        emitter.xAcceleration = 0

        // Scale
        emitter.particleScale = 1.2
        emitter.particleScaleRange = 0.6
        emitter.particleScaleSpeed = -0.1

        // Rotation — tumbling confetti
        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 4.0

        // Alpha — fade out near end of life
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.25

        // Colors — vibrant multicolored confetti
        let colors: [NSColor] = [
            NSColor(red: 1.0, green: 0.15, blue: 0.25, alpha: 1.0),  // Red
            NSColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0),   // Gold
            NSColor(red: 0.15, green: 0.85, blue: 0.35, alpha: 1.0), // Green
            NSColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0),    // Blue
            NSColor(red: 0.85, green: 0.2, blue: 1.0, alpha: 1.0),   // Purple
            NSColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1.0),    // Orange
            NSColor(red: 0.0, green: 0.9, blue: 0.85, alpha: 1.0),   // Cyan
            NSColor(red: 1.0, green: 0.4, blue: 0.7, alpha: 1.0),    // Pink
        ]

        let keyTimes: [NSNumber] = [0.0, 0.14, 0.28, 0.42, 0.57, 0.71, 0.85, 1.0]
        emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: colors, times: keyTimes)
        emitter.particleColorBlendFactor = 1.0

        // Position range for spread at emission point
        emitter.particlePositionRange = CGVector(dx: 20, dy: 10)

        return emitter
    }
}
