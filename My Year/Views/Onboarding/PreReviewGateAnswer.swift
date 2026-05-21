enum PreReviewGateAnswer: String, CaseIterable, Identifiable {
  case positive
  case neutral
  case negative
  case skip

  var id: String { rawValue }

  var isPositive: Bool {
    self == .positive
  }
}
