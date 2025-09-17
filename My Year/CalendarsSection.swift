import RevenueCat
import SharedModels
import SwiftUI
import SwiftfulRouting

struct CalendarsSection: View {
  @State private var customerInfo: CustomerInfo?
  @ObservedObject private var store = CustomCalendarStore.shared
  @EnvironmentObject var onboarding: OnboardingManager
  @ObservedObject private var valuationStore = ValuationStore.shared

  @State private var selectedIndex: Int = 0
  @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = true

  @Environment(\.router) private var router

  @State private var position = ScrollPosition(edge: .leading)

  var body: some View {
    RouterView { _ in
      GeometryReader { geometry in
        let width = geometry.size.width
        ScrollView(.horizontal) {
          LazyHStack(spacing: 0) {
            // Year Grid
            if isMoodTrackingEnabled {
              MoodTrackingCalendar()
                .id("mood")
                .frame(width: width)
                .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                .slide()

            }

            AllCalendarsRecapView()
              .id("recap")
              .frame(width: width)
              .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
              .slide()

            // Custom Calendars
            ForEach(Array(store.calendars.enumerated()), id: \.element.id) { index, calendar in
              CustomCalendarView(calendar: calendar)
                .id(index.description)
                .frame(width: width)
                .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                .slide()

            }

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
                  store.addCalendar(newCalendar)
                  if let index = store.calendars.firstIndex(where: { $0.id == newCalendar.id }) {
                    position.scrollTo(id: index.description)
                  }
                  router.dismissScreen()
                  addPositiveEvent(.createdCalendar)
                }
              }
            }
          }
          .scrollTargetLayout()
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
        .background(Color("surface-muted"))
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          HStack(spacing: 4) {
            #if DEBUG
              Button(action: {
                onboarding.reset()
              }) {
                Image(systemName: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
                  .foregroundColor(Color("text-tertiary"))
                  .font(.system(size: 12))
              }

            #endif

            Button(action: {
              router.showScreen(.sheet) { _ in
                SettingsView()
              }
            }) {
              Image(systemName: "gearshape")
                .foregroundColor(Color("text-tertiary"))
                .font(.system(size: 12))
            }
            Button(action: {
              router.showScreen(.sheet) { _ in
                CalendarsOverview(store: store, valuationStore: valuationStore, scrollPosition: $position)
              }
            }) {
              Image(systemName: "square.grid.2x2")
                .font(.system(size: 12))
                .foregroundColor(Color("text-tertiary"))
            }
          }
        }
      }
    }
  }
}
