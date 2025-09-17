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

  var body: some View {
    RouterView { _ in
      VStack {
        TabView(
          selection: $selectedIndex.onChange { _ in
            Task {
              await hapticFeedback()
            }
          }
        ) {
          // Year Grid
          if isMoodTrackingEnabled {
            MoodTrackingCalendar()
              .tag(-10)
          }

          AllCalendarsRecapView()
            .tag(-1)

          // Custom Calendars
          ForEach(Array(store.calendars.enumerated()), id: \.element.id) { index, calendar in
            CustomCalendarView(calendar: calendar)
              .tag(index)
              .padding(.bottom, 46)
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
            Spacer()
          }
          .tag(store.calendars.count + 3)
          .onTapGesture {
            router.showScreen(.sheet) { _ in
              CreateCalendarView { newCalendar in
                store.addCalendar(newCalendar)
                selectedIndex = store.calendars.count
                router.dismissScreen()
                addPositiveEvent(.createdCalendar)
              }
            }
          }
        }.ignoresSafeArea(.all, edges: .bottom)
          .offset(y: 0)
          .overlay {
            // Upper separator
            VStack {
              CustomSeparator()
              Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          }
          .tabViewStyle(.page(indexDisplayMode: .never))
          .indexViewStyle(.page(backgroundDisplayMode: .never))
          .overlay {
            HStack {
              Text("Yearlit")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color("text-tertiary"))

              if customerInfo?.entitlements["premium"]?.isActive ?? false {
                Image(systemName: "checkmark.seal.fill")
                  .font(.caption)
                  .foregroundColor(Color("mood-excellent"))
                  .shadow(color: Color("mood-excellent").opacity(0.5), radius: 10)
              }
            }.position(x: 50, y: -30)
          }
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
                CalendarsOverview(store: store, valuationStore: valuationStore, selectedIndex: $selectedIndex)
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
