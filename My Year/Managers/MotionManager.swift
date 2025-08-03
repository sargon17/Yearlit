import Combine
import CoreMotion
import SwiftUI

/// Singleton motion manager with observer pattern for efficient, low-latency updates.
/// Use `MotionManager.shared` everywhere; do NOT instantiate per component.
/// This avoids redundant sensor polling and ensures all listeners get the same data.
final class MotionManager: ObservableObject {
  static let shared = MotionManager()

  private let motionManager = CMMotionManager()
  @Published private(set) var x: CGFloat = 0.0
  @Published private(set) var y: CGFloat = 0.0

  private var observers: [(CGFloat, CGFloat) -> Void] = []
  private let queue = DispatchQueue(label: "MotionManagerQueue")

  private init() {
    motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data: CMDeviceMotion?, error) in
      guard let self = self, let motion = data?.attitude else { return }
      let newX = motion.roll
      let newY = motion.pitch

      // Only notify if values changed significantly to avoid unnecessary updates
      if abs(self.x - newX) > 0.001 || abs(self.y - newY) > 0.001 {
        self.x = newX
        self.y = newY
        self.notifyObservers()
      }
    }
  }

  /// Register a closure to receive motion updates.
  /// The closure is called on the main thread.
  func addObserver(_ observer: @escaping (CGFloat, CGFloat) -> Void) {
    queue.async {
      self.observers.append(observer)
      // Immediately notify with current values
      DispatchQueue.main.async {
        observer(self.x, self.y)
      }
    }
  }

  /// Remove all observers (optional, for cleanup).
  func removeAllObservers() {
    queue.async {
      self.observers.removeAll()
    }
  }

  private func notifyObservers() {
    let x = self.x
    let y = self.y
    queue.async {
      let observersCopy = self.observers
      DispatchQueue.main.async {
        for observer in observersCopy {
          observer(x, y)
        }
      }
    }
  }

  func stop() {
    motionManager.stopDeviceMotionUpdates()
    removeAllObservers()
  }
}
/// NOTE: Do NOT create a new instance of MotionManager in each component.
/// Always use `MotionManager.shared` to avoid redundant sensor polling and maximize performance.
