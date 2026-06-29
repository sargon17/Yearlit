import RevenueCat
import SharedModels
import SwiftfulRouting
import SwiftUI

struct CalendarsSection: View {
  @State private var customerInfo: CustomerInfo?
  @ObservedObject var store = CustomCalendarStore.shared
  @EnvironmentObject var onboarding: OnboardingManager
  @ObservedObject var valuationStore = ValuationStore.shared

  @State private var selectedIndex: Int = 0
  @AppStorage(AppStorageKeys.isMoodTrackingEnabled) var isMoodTrackingEnabled: Bool = false
  @AppStorage(AppStorageKeys.isRecapViewEnabled) var isRecapViewEnabled: Bool = false
  @AppStorage(AppStorageKeys.cleanScreenshotsEnabled) var cleanScreenshotsEnabled: Bool = false
  @ObservedObject var timelinePreference = TimelinePreferenceManager.shared

  @Environment(\.router) var router

  @State var position = ScrollPosition(idType: String.self)
  @State var visibleSlideId: String?
  @State var pendingCalendarId: String?
  @State var isTimelinePreferenceSheetPresented = false
  @State var hasTrackedRecapView = false
  @State var lastHapticSlideId: String?

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
                  CreateCalendarChoiceView { newCalendar in
                    pendingCalendarId = newCalendar.id.uuidString
                    let isFirstCalendar = store.snapshot.calendars.isEmpty
                    store.addCalendar(newCalendar)
                    CalendarAnalyticsTracker.shared.trackCalendarCreated(
                      calendar: newCalendar,
                      isFirstCalendar: isFirstCalendar
                    )
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
          lastHapticSlideId = currentId
          trackRecapViewIfNeeded(for: currentId)
        }
        .onChange(of: position.viewID(type: String.self)) { _, newValue in
          if let newValue {
            visibleSlideId = newValue
            playSlideSettledHapticIfNeeded(for: newValue)
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
        if RevenueCatClient.isConfigured {
          Purchases.shared.getCustomerInfo { info, _ in
            customerInfo = info
          }
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

  func slideIds(for snapshot: CustomCalendarStoreSnapshot) -> [String] {
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
}
