func addPositiveEvent(_ event: PositiveEvent) {
  Task { @MainActor in
    ReviewPrompter.shared.recordAndConsiderPrompt(event)
  }
}
