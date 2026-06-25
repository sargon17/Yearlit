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
  @FocusState private var isFeedbackFocused: Bool

  var body: some View {
    OnboardingStepContainer(overlayHeight: 0.9, actionsBottomPadding: 2) {
      heroContent
    } content: {
    } actions: {
      VStack {

        if isCollectingFeedback {
          feedbackForm
        } else {
          answerButtons
        }
      }.padding(.top, 12)
    }
    .alert("Could not send feedback", isPresented: $submitFailed) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Please try again later.")
    }
    .ignoresSafeArea(.container)
  }

  private var heroContent: some View {
    VStack(alignment: .leading, spacing: 12) {
      Spacer(minLength: 80)

      Text("Enjoying Yearlit so far?")
        .font(AppFont.pixelCircle(32))
        .lineLimit(3)
        .minimumScaleFactor(0.65)
        .foregroundStyle(.textPrimary)

      Text("Tell us how it's going — it only takes a tap.")
        .font(AppFont.mono(14))
        .foregroundStyle(.textSecondary)
        .padding(.bottom, 32)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    .padding(.horizontal, 18)
  }

  private var answerButtons: some View {
    VStack(spacing: 2) {
      OnboardingView.ForwardButton(
        title: "Love it",
        onTap: {
          trackAnswer("yes")
          requestReviewAfterDismissal()
        }
      )

      OnboardingView.ForwardButton(
        title: "Not really",
        onTap: {
          trackAnswer("no")
          isCollectingFeedback = true
        },
        style: .secondary
      )

      Button {
        trackAnswer("maybe")
        close()
      } label: {
        Text("Maybe later")
          .font(AppFont.mono(14, weight: .medium))
          .foregroundStyle(.textTertiary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 10)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }

  private var feedbackForm: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("What would make it better?")
        .font(AppFont.pixelCircle(24))
        .foregroundStyle(.textPrimary)

      TextField("Share what's frustrating or missing", text: $feedbackText, axis: .vertical)
        .font(AppFont.sans(16))
        .foregroundStyle(.textPrimary)
        .padding(14)
        .background(.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .sameLevelBorder(radius: 4, color: .surfaceMuted, isFlat: true)
        .lineLimit(5...9)
        .focused($isFeedbackFocused)
        .task {
          await Task.yield()
          isFeedbackFocused = true
        }
        .onChange(of: feedbackText) { _, newValue in
          trackFeedbackStartedIfNeeded(newValue)
        }

      OnboardingView.ForwardButton(
        title: isSubmittingFeedback ? "Sending…" : "Send feedback",
        onTap: submitFeedback,
        style: trimmedFeedback.isEmpty || isSubmittingFeedback ? .disabled : .primary
      )
    }
  }

  private var closeButton: some View {
    Button {
      trackAnswer("not_now")
      close()
    } label: {
      Image(systemName: "xmark")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.textSecondary)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .background(.surfaceMuted.opacity(0.75), in: Circle())
    .accessibilityLabel("Not now")
    .padding(.top, 18)
    .padding(.trailing, 10)
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
