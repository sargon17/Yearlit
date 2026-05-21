enum PreReviewGateAnswer: String, CaseIterable, Identifiable {
  case positive
  case negative

  var id: String { rawValue }

  var isPositive: Bool {
    self == .positive
  }
}
