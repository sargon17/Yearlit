import SharedModels
import SwiftUI

struct ReadyWidgetsView: View {
  let onContinue: () -> Void
  @Environment(\.colorScheme) private var colorScheme

  private var backgroundColor: Color {
    WidgetStyle.surfaceMutedColor(for: colorScheme)
  }

  private var primaryTextColor: Color {
    WidgetStyle.textPrimaryColor(for: colorScheme)
  }

  var body: some View {
    OnboardingStepContainer {
      WidgetPreviewFrame(family: .medium) {
        YearProgressWidgetDisplayView(
          family: .medium,
          referenceDate: Date(),
          backgroundColor: backgroundColor,
          textPrimaryColor: primaryTextColor
        )
      }
      .padding(.horizontal)
    } content: {
      VStack(alignment: .leading) {
        OnboardingView.Title("Everything is ready")
        OnboardingView.Caption("Your first habit is set.")
        OnboardingView.Caption("Add a Yearlit widget to keep your promise where you’ll see it.")
          .padding(.bottom)
        OnboardingView.Caption("The more visible your habit is, the easier it is to return.")
      }
    } actions: {
      OnboardingView.ForwardButton(title: "Continue", onTap: onContinue)
    }
  }
}
