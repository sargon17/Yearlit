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
      VStack(alignment: .leading, spacing: 18) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Are you liking Yearlit so far?")
            .font(AppFont.sans(28))
            .fontWeight(.black)
            .foregroundColor(.textPrimary)

          Text("Your answer helps decide what happens next.")
            .body()
            .foregroundColor(.textSecondary)
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
          Button("Not now") {
            trackAnswer("not_now")
            close()
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
    VStack(spacing: 10) {
      Button {
        trackAnswer("yes")
        requestReviewAfterDismissal()
      } label: {
        Label("Yes", systemImage: "heart.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)

      Button {
        trackAnswer("no")
        isCollectingFeedback = true
      } label: {
        Label("No", systemImage: "exclamationmark.bubble")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .controlSize(.large)

      Button {
        trackAnswer("maybe")
        close()
      } label: {
        Label("Maybe", systemImage: "clock")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .controlSize(.large)
    }
  }

  private var feedbackForm: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("What is not working?")
        .h4()

      TextField("Tell us what felt wrong or missing", text: $feedbackText, axis: .vertical)
        .textFieldStyle(.roundedBorder)
        .lineLimit(5...9)
        .onChange(of: feedbackText) { _, newValue in
          trackFeedbackStartedIfNeeded(newValue)
        }

      Button {
        submitFeedback()
      } label: {
        Label(isSubmittingFeedback ? "Sending" : "Send feedback", systemImage: "paperplane")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(isSubmittingFeedback || trimmedFeedback.isEmpty)
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
