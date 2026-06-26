import CoreHaptics
import SwiftfulHaptics
import SwiftUI

// A description
// - Parameter option:
// UISelectionFeedbackGenerator
// .selection

// UIImpactFeedbackGenerator
// .soft
// .rigid
// .light
// .medium
// .heavy

// UINotificationFeedbackGenerator
//  .success
//  .error
//  .warning

// CoreHaptics: CHHapticEngine
// .boing()
// .boing(duration: 0.25)
// .drums
// .heartBeats()
//  .heartBeats(count: 3, durationPerBeat: 0.255)
// .inflate()
// .inflate(duration: 1.7)
// .oscillate()
// .oscillate(duration: 3.0)
//  .pop()
//  .pop(duration: 0.2)

// Developer can inject custom pattern in to CoreHaptics
// .custom(events: [CHHapticEvent], parameters: [CHHapticDynamicParameter])
//  .customCurve(events: [CHHapticEvent], parameterCurves: [CHHapticParameterCurve])

func hapticFeedback(_ option: HapticOption = .light) async {
    let hapticManager = HapticManager(logger: nil)
    await hapticManager.prepare(option: option)
    await hapticManager.play(option: option)
}

func checkInRippleHapticFeedback() async {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
        await hapticFeedback(.soft)
        return
    }

    await hapticFeedback(.customCurve(events: checkInHapticEvents, parameterCurves: checkInHapticCurves))
}

private let checkInHapticEvents: [CHHapticEvent] = [
    CHHapticEvent(
        eventType: .hapticContinuous,
        parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.16)
        ],
        relativeTime: 0,
        duration: 1.25
    )
]

private let checkInHapticCurves: [CHHapticParameterCurve] = [
    CHHapticParameterCurve(
        parameterID: .hapticIntensityControl,
        controlPoints: [
            CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.16),
            CHHapticParameterCurve.ControlPoint(relativeTime: 0.1, value: 0.72),
            CHHapticParameterCurve.ControlPoint(relativeTime: 0.34, value: 0.52),
            CHHapticParameterCurve.ControlPoint(relativeTime: 0.68, value: 0.3),
            CHHapticParameterCurve.ControlPoint(relativeTime: 1.0, value: 0.14),
            CHHapticParameterCurve.ControlPoint(relativeTime: 1.25, value: 0)
        ],
        relativeTime: 0
    ),
    CHHapticParameterCurve(
        parameterID: .hapticSharpnessControl,
        controlPoints: [
            CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: -0.35),
            CHHapticParameterCurve.ControlPoint(relativeTime: 0.3, value: -0.2),
            CHHapticParameterCurve.ControlPoint(relativeTime: 1.25, value: -0.5)
        ],
        relativeTime: 0
    )
]
