func addPositiveEvent(_ event: PositiveEvent) {
  Task { @MainActor in
    guard UpgradePrompter.shared.activePrompt == nil else {
      ReviewPrompter.shared.record(event)
      UpgradePrompter.shared.record(event)
      return
    }

    ReviewPrompter.shared.recordAndConsiderPrompt(event)
    UpgradePrompter.shared.record(event)
    guard ReviewPrompter.shared.activePrompt == nil else { return }
    UpgradePrompter.shared.considerPrompt(for: event)
  }
}
