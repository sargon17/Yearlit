import CoreMotion
import Foundation

final class MotionTiltManager: ObservableObject {
    @Published var pitch: Double = 0
    @Published var roll: Double = 0

    private let manager = CMMotionManager()
    private let maxAngle: Double = 6
    private let smoothing: Double = 0.12
    private var referenceGravity: CMAcceleration?

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1 / 60
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let gravity = motion.gravity
            if referenceGravity == nil {
                referenceGravity = gravity
            }
            let ref = referenceGravity ?? gravity
            let dx = gravity.x - ref.x
            let dy = gravity.y - ref.y
            let targetRoll = clamp(dx * maxAngle * 1.4, maxAngle: maxAngle)
            let targetPitch = clamp(-dy * maxAngle * 1.4, maxAngle: maxAngle)
            pitch = lerp(from: pitch, to: targetPitch, t: smoothing)
            roll = lerp(from: roll, to: targetRoll, t: smoothing)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        referenceGravity = nil
    }

    private func clamp(_ value: Double, maxAngle: Double) -> Double {
        min(maxAngle, max(-maxAngle, value))
    }

    private func lerp(from: Double, to: Double, t: Double) -> Double {
        from + (to - from) * t
    }
}
