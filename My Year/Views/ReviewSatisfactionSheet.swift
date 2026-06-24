import SwiftUI

struct ReviewSatisfactionSheet: View {
  @ObservedObject var prompter: ReviewPrompter
  let context: ReviewPromptContext
  @EnvironmentObject private var featureRequestManager: FeatureRequestManager
  @Environment(\.dismiss) private var dismiss

  @State private var feedbackText = ""
  @State private var isCollectingFeedback = false
  @State private var isSubmittingFeedback = false
  @State private var submitFailed = false
  @State private var hasTrackedFeedbackStarted = false
  @State private var hasTrackedAnswer = false

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 10) {
          Text("Are you liking Yearlit so far?")
            .font(AppFont.pixelCircle(26))
            .foregroundStyle(.textPrimary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)

          Text("Your answer helps decide what happens next.")
            .font(AppFont.mono(14))
            .foregroundStyle(.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        if isCollectingFeedback {
          feedbackForm
        } else {
          answerButtons
        }

        Spacer()
      }
      .padding(20)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            trackAnswer("not_now")
            close()
          } label: {
            Text("Not now")
              .font(AppFont.mono(14, weight: .medium))
              .foregroundStyle(.textSecondary)
          }
        }
      }
      .alert("Could not send feedback", isPresented: $submitFailed) {
        Button("OK", role: .cancel) {}
      } message: {
        Text("Please try again later.")
      }
    }
  }

  private var answerButtons: some View {
    VStack(spacing: 12) {
      styledButton("Yes", style: .primary) {
        trackAnswer("yes")
        requestReviewAfterDismissal()
      }

      styledButton("No", style: .secondary) {
        trackAnswer("no")
        isCollectingFeedback = true
      }

      styledButton("Maybe later", style: .link) {
        trackAnswer("maybe")
        close()
      }
    }
  }

  private var feedbackForm: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("What is not working?")
        .font(AppFont.mono(16, weight: .bold))
        .foregroundStyle(.textPrimary)

      TextField("Tell us what felt wrong or missing", text: $feedbackText, axis: .vertical)
        .lineLimit(5...9)
        .inputStyle(color: .textPrimary)
        .onChange(of: feedbackText) { _, newValue in
          trackFeedbackStartedIfNeeded(newValue)
        }

      styledButton(
        isSubmittingFeedback ? "Sending" : "Send feedback",
        style: .primary,
        isDisabled: isSubmittingFeedback || trimmedFeedback.isEmpty
      ) {
        submitFeedback()
      }
    }
  }

  private enum AnswerButtonStyle {
    case primary
    case secondary
    case link
  }

  @ViewBuilder
  private func styledButton(
    _ title: LocalizedStringKey,
    style: AnswerButtonStyle,
    isDisabled: Bool = false,
    action: @escaping () -> Void
  ) -> some View {
    let button = Button(action: action) {
      Text(title)
        .font(AppFont.mono(style == .primary ? 18 : 16, weight: .bold))
        .foregroundStyle(foregroundColor(for: style))
        .underline(style == .link)
        .padding(.horizontal, style == .link ? 0 : 14)
        .padding(.vertical, style == .link ? 6 : 16)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(backgroundColor(for: style))
    }
    .buttonStyle(.plain)
    .disabled(isDisabled)
    .opacity(isDisabled ? 0.5 : 1)
    .accessibilityLabel(Text(title))

    switch style {
    case .primary:
      VStack {
        button
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .sameLevelBorder(radius: 4, color: .brand)
      }
      .padding(2)
    case .secondary:
      VStack {
        button
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .sameLevelBorder(radius: 4, color: .buttonBackground)
      }
      .padding(2)
    case .link:
      button
    }
  }

  private func foregroundColor(for style: AnswerButtonStyle) -> Color {
    switch style {
    case .primary:
      return .brandInverted
    case .secondary:
      return .buttonForeground
    case .link:
      return .textTertiary
    }
  }

  private func backgroundColor(for style: AnswerButtonStyle) -> Color {
    switch style {
    case .primary:
      return .brand
    case .secondary:
      return .buttonBackground
    case .link:
      return .clear
    }
  }

  private var trimmedFeedback: String {
    feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func submitFeedback() {
    guard !trimmedFeedback.isEmpty else { return }
    isSubmittingFeedback = true
    let feedbackLength = trimmedFeedback.count

    Task {
      await featureRequestManager.createRequest(
        text: "Review feedback: user is not enjoying Yearlit",
        description: """
        \(trimmedFeedback)

        Source: in-app satisfaction prompt after a positive app event.
        User selected: No.
        """,
        kind: .complaint,
        onSuccess: {
          trackFeedbackSubmitted(characterCount: feedbackLength)
          close()
        },
        onError: {
          isSubmittingFeedback = false
          trackFeedbackSubmitFailed(characterCount: feedbackLength)
          submitFailed = true
        }
      )
    }
  }

  private func close() {
    prompter.dismissActivePrompt()
    dismiss()
  }

  private func requestReviewAfterDismissal() {
    close()
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 350_000_000)
      prompter.requestReviewNow(context: context)
    }
  }

  private func trackAnswer(_ answer: String) {
    guard !hasTrackedAnswer else { return }
    hasTrackedAnswer = true
    Analytics.shared.track(
      .reviewSatisfactionPromptAnswered,
      properties: analyticsProperties(answer: answer)
    )
  }

  private func trackFeedbackSubmitted(characterCount: Int) {
    Analytics.shared.track(
      .reviewFeedbackSubmitted,
      properties: analyticsProperties(answer: "no").merging([
        "feedback_character_count": .int(characterCount)
      ]) { _, new in new }
    )
  }

  private func trackFeedbackSubmitFailed(characterCount: Int) {
    Analytics.shared.track(
      .reviewFeedbackSubmitFailed,
      properties: analyticsProperties(answer: "no").merging([
        "feedback_character_count": .int(characterCount)
      ]) { _, new in new }
    )
  }

  private func trackFeedbackStartedIfNeeded(_ text: String) {
    guard !hasTrackedFeedbackStarted else { return }
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    hasTrackedFeedbackStarted = true
    Analytics.shared.track(
      .reviewFeedbackStarted,
      properties: analyticsProperties(answer: "no")
    )
  }

  private func analyticsProperties(answer: String) -> [String: AnalyticsPropertyValue] {
    [
      "answer": .string(answer),
      "positive_event": .string(context.event.rawValue),
      "trigger": .string(context.trigger.rawValue)
    ]
  }
}
