import RevenueCat
import SharedModels
import SwiftfulRouting
import SwiftUI

struct CalendarsSection: View {
  @State private var customerInfo: CustomerInfo?
  @ObservedObject private var store = CustomCalendarStore.shared
  @EnvironmentObject var onboarding: OnboardingManager
  @ObservedObject private var valuationStore = ValuationStore.shared

  @State private var selectedIndex: Int = 0
  @AppStorage(AppStorageKeys.isMoodTrackingEnabled) var isMoodTrackingEnabled: Bool = false
  @AppStorage(AppStorageKeys.isRecapViewEnabled) var isRecapViewEnabled: Bool = false
  @ObservedObject private var timelinePreference = TimelinePreferenceManager.shared

  @Environment(\.router) private var router

  @State private var position = ScrollPosition(idType: String.self)
  @State private var visibleSlideId: String?
  @State private var pendingCalendarId: String?
  @State private var isTimelinePreferenceSheetPresented = false
  @State private var hasTrackedRecapView = false

  var body: some View {
    let snapshot = store.snapshot
    let slideIds = slideIds(for: snapshot)

    VStack(spacing: 0) {
      // custom toolbar
      HStack {
        HStack(spacing: 6) {
          Text("Yearlit")
            .font(AppFont.mono(14, weight: .bold))
          if isPremium(customerInfo: customerInfo) {
            Image(systemName: "checkmark.seal")
              .font(.system(size: 12, weight: .bold))
              .foregroundStyle(.purple)
          }
        }

        Spacer()

        toolbar
      }.padding(.all, 16)

      CustomSeparator()

      GeometryReader { geometry in
        let width = geometry.size.width
        ScrollView(.horizontal) {
          LazyHStack(spacing: 0) {
            // Year Grid
            if isMoodTrackingEnabled {
              slideContent(id: "mood", slideIds: slideIds) {
                MoodTrackingCalendar()
              }
                .id("mood")
                .frame(width: width)
                .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                .slide()
            }

            if isRecapViewEnabled {
              slideContent(id: "recap", slideIds: slideIds) {
                AllCalendarsRecapView()
              }
                .id("recap")
                .frame(width: width)
                .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                .slide()
            }

            // Custom Calendars
            let activeCalendars = snapshot.activeCalendars
            // Use stable IDs to keep paging aligned when filtering.
            ForEach(activeCalendars, id: \.id) { calendar in
              let slideId = calendar.id.uuidString
              slideContent(id: slideId, slideIds: slideIds) {
                CustomCalendarView(calendar: calendar)
              }
                .id(slideId)
                .frame(width: width)
                .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                .slide()
            }

            if snapshot.isLoading && activeCalendars.isEmpty {
              ProgressView()
                .tint(Color("text-tertiary"))
                .frame(width: width)
                .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                .slide()
                .id("calendar_loading")
            } else {
              // Add Calendar Button
              VStack {
                Spacer()
                VStack(spacing: 16) {
                  Image(systemName: "plus")
                    .font(.system(size: 42))
                    .foregroundStyle(Color("text-tertiary"))
                  Text("Add Calendar")
                    .font(.headline)
                    .foregroundColor(Color("text-primary"))
                }
                .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                Spacer()
              }
              .frame(width: width)
              .slide()
              .id("add_calendar")
              .onTapGesture {
                router.showScreen(.sheet) { _ in
                  CreateCalendarView { newCalendar in
                    pendingCalendarId = newCalendar.id.uuidString
                    let isFirstCalendar = store.snapshot.calendars.isEmpty
                    store.addCalendar(newCalendar)
                    CalendarAnalyticsTracker.shared.trackCalendarCreated(
                      calendar: newCalendar,
                      isFirstCalendar: isFirstCalendar
                    )
                    router.dismissScreen()
                    addPositiveEvent(.createdCalendar)
                  }
                }
              }
            }
          }
          .scrollTargetLayout()
          .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
          .overlay {
            HStack {
              Rectangle()
                .fill(Color("devider-top"))
                .frame(maxHeight: .infinity, alignment: .trailing)
                .frame(maxWidth: 1)
                .ignoresSafeArea(.all, edges: .vertical)
                .offset(x: -1)

              Spacer()

              Rectangle()
                .fill(Color("devider-bottom"))
                .frame(maxHeight: .infinity, alignment: .trailing)
                .frame(maxWidth: 1)
                .ignoresSafeArea(.all, edges: .vertical)
                .offset(x: 1)
            }
          }
        }
        .scrollTargetBehavior(.paging)
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .scrollPosition($position)
        .scrollContentBackground(.hidden)
        .onAppear {
          let currentId = position.viewID(type: String.self) ?? slideIds.first
          visibleSlideId = currentId
          trackRecapViewIfNeeded(for: currentId)
        }
        .onChange(of: position.viewID(type: String.self)) { _, newValue in
          if let newValue {
            visibleSlideId = newValue
          }
          trackRecapViewIfNeeded(for: newValue)
        }
        .onChange(of: slideIds) { _, newValue in
          if visibleSlideId.map({ !newValue.contains($0) }) ?? true {
            visibleSlideId = newValue.first
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .onOpenURL { url in
        handleCalendarDeepLink(url)
      }
      .onChange(of: snapshot.activeCalendars.map(\.id)) { _, _ in
        scrollToPendingCalendarIfAvailable()
      }

      .onAppear {
        Purchases.shared.getCustomerInfo { info, _ in
          customerInfo = info
        }
      }
    }
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .fullScreenCover(isPresented: $isTimelinePreferenceSheetPresented) {
      TimelinePreferenceChoiceSheet { mode in
        timelinePreference.setMode(mode)
        isTimelinePreferenceSheetPresented = false
      }
    }
  }

  @ViewBuilder
  private func slideContent<Content: View>(
    id: String,
    slideIds: [String],
    @ViewBuilder content: () -> Content
  ) -> some View {
    if shouldRenderSlide(id: id, slideIds: slideIds) {
      content()
    } else {
      Color.clear
    }
  }

  private func shouldRenderSlide(id: String, slideIds: [String]) -> Bool {
    guard let index = slideIds.firstIndex(of: id) else { return true }
    guard let visibleSlideId, let visibleIndex = slideIds.firstIndex(of: visibleSlideId) else {
      return index <= 1
    }
    return abs(index - visibleIndex) <= 1
  }

  private func slideIds(for snapshot: CustomCalendarStoreSnapshot) -> [String] {
    var ids: [String] = []
    if isMoodTrackingEnabled {
      ids.append("mood")
    }
    if isRecapViewEnabled {
      ids.append("recap")
    }
    ids.append(contentsOf: snapshot.activeCalendars.map { $0.id.uuidString })
    ids.append(snapshot.isLoading && snapshot.activeCalendars.isEmpty ? "calendar_loading" : "add_calendar")
    return ids
  }

  var toolbar: some View {
    HStack(spacing: 12) {
      #if DEBUG
        Button(action: {
          onboarding.reset()
        }) {
          Image(systemName: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
            // .foregroundColor(Color("text-tertiary"))
            .font(.system(size: 16))
        }

        Button(action: {
          isTimelinePreferenceSheetPresented = true
        }) {
          Image(systemName: "calendar.badge.clock")
            .font(.system(size: 16))
        }
        .accessibilityLabel("Show Timeline Choice Sheet")

        Button(action: {
          router.showScreen(.sheet) { _ in
            OnboardingPaywall {
              router.dismissScreen()
            }
          }
        }) {
          Image(systemName: "dollarsign.circle")
            .font(.system(size: 16))
        }
        .accessibilityLabel("Show Paywall")
      #endif

      Button(action: {
        router.showScreen(.sheet) { _ in
          SettingsView()
        }
      }) {
        Image(systemName: "gearshape")
          // .foregroundColor(Color("text-tertiary"))
          .font(.system(size: 16))
      }
      Button(action: {
        Analytics.shared.track(.calendarsOverviewViewed)
        router.showScreen(.sheet) { _ in
          CalendarsOverview(store: store, valuationStore: valuationStore, scrollPosition: $position)
        }
      }) {
        Image(systemName: "rectangle.split.1x2")
          .font(.system(size: 16))
        // .foregroundColor(Color("text-tertiary"))
      }
    }
  }

  private func handleCalendarDeepLink(_ url: URL) {
    guard url.scheme == "my-year", url.host == "calendar" else { return }
    let idString = url.pathComponents.dropFirst().first
    guard let idString else { return }

    pendingCalendarId = idString
    store.loadCalendars(showLoadingIndicator: false)
    scrollToCalendarIfAvailable(idString)
  }

  private func scrollToPendingCalendarIfAvailable() {
    guard let pendingCalendarId else { return }
    scrollToCalendarIfAvailable(pendingCalendarId)
  }

  private func scrollToCalendarIfAvailable(_ id: String) {
    guard store.snapshot.activeCalendars.contains(where: { $0.id.uuidString == id }) else { return }
    pendingCalendarId = nil

    Task { @MainActor in
      await Task.yield()
      position.scrollTo(id: id)
    }
  }

  private func trackRecapViewIfNeeded(for viewID: String?) {
    guard viewID == "recap", !hasTrackedRecapView else { return }
    hasTrackedRecapView = true
    Analytics.shared.track(.recapViewViewed)
  }
}
