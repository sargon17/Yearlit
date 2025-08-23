func addPositiveEvent(_ event: PositiveEvent) {
  ReviewPrompter.shared.record(event)
  ReviewPrompter.shared.considerPromptSwiftUI(fallbackAppID: "67404909951")
}
