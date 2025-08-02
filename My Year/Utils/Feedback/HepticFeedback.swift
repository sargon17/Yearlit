import SwiftUI
import SwiftfulHaptics

/// A description
/// - Parameter option:
/// UISelectionFeedbackGenerator
/// .selection

/// UIImpactFeedbackGenerator
/// .soft
/// .rigid
/// .light
/// .medium
/// .heavy

/// UINotificationFeedbackGenerator
///  .success
///  .error
///  .warning

/// CoreHaptics: CHHapticEngine
/// .boing()
/// .boing(duration: 0.25)
/// .drums
/// .heartBeats()
///  .heartBeats(count: 3, durationPerBeat: 0.255)
/// .inflate()
/// .inflate(duration: 1.7)
/// .oscillate()
/// .oscillate(duration: 3.0)
///  .pop()
///  .pop(duration: 0.2)

/// Developer can inject custom pattern in to CoreHaptics
/// .custom(events: [CHHapticEvent], parameters: [CHHapticDynamicParameter])
///  .customCurve(events: [CHHapticEvent], parameterCurves: [CHHapticParameterCurve])

func hepticFeedback(option: HapticOption = .light) async {
  let hapticManager = HapticManager(logger: nil)
  await hapticManager.prepare(option: option)
  await hapticManager.play(option: option)
}
