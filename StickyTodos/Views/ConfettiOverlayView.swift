import SwiftUI
import SpriteKit

struct ConfettiOverlayView: View {
    let scene: ConfettiScene

    init() {
        let scene = ConfettiScene()
        scene.size = CGSize(width: 400, height: 600)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        self.scene = scene
    }

    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene, options: [.allowsTransparency])
                .onChange(of: geometry.size) { _, newSize in
                    scene.size = newSize
                }
                .onAppear {
                    scene.size = geometry.size
                }
        }
        .allowsHitTesting(false)
    }
}
