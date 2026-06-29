import SwiftfulRouting
import SwiftUI

extension CalendarsSection {
  var toolbar: some View {
    HStack(spacing: 12) {
      debugToolbarActions
      settingsButton
      overviewButton
    }
  }

  @ViewBuilder
  private var debugToolbarActions: some View {
    #if DEBUG
      if !cleanScreenshotsEnabled {
        Button(action: {
          onboarding.reset()
        }, label: {
          Image(systemName: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
            .font(.system(size: 16))
        })

        Button(action: {
          isTimelinePreferenceSheetPresented = true
        }, label: {
          Image(systemName: "calendar.badge.clock")
            .font(.system(size: 16))
        })
        .accessibilityLabel("Show Timeline Choice Sheet")

        Button(action: {
          router.showScreen(.sheet) { _ in
            OnboardingPaywall(isPresentedAsSheet: true) {
              router.dismissScreen()
            }
          }
        }, label: {
          Image(systemName: "dollarsign.circle")
            .font(.system(size: 16))
        })
        .accessibilityLabel("Show Paywall")
      }
    #endif
  }

  private var settingsButton: some View {
    Button(action: {
      router.showScreen(.sheet) { _ in
        SettingsView()
      }
    }, label: {
      Image(systemName: "gearshape")
        .font(.system(size: 16))
    })
  }

  private var overviewButton: some View {
    Button(action: {
      Analytics.shared.track(.calendarsOverviewViewed)
      router.showScreen(.sheet) { _ in
        CalendarsOverview(store: store, valuationStore: valuationStore, scrollPosition: $position)
      }
    }, label: {
      Image(systemName: "rectangle.split.1x2")
        .font(.system(size: 16))
    })
  }
}
