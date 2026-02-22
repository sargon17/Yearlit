import RevenueCat
import SharedModels
import SwiftfulRouting
import SwiftUI

struct CalendarsSection: View {
    @State private var customerInfo: CustomerInfo?
    @ObservedObject private var store = CustomCalendarStore.shared
    @EnvironmentObject var onboarding: OnboardingManager
    @EnvironmentObject private var whatsNewManager: WhatsNewManager
    @ObservedObject private var valuationStore = ValuationStore.shared

    @State private var selectedIndex: Int = 0
    @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = true

    @Environment(\.router) private var router

    @State private var position = ScrollPosition(edge: .leading)
    @State private var pendingCalendarId: String?

    var body: some View {
        VStack(spacing: 0) {
            // custom toolbar
            HStack {
                HStack(spacing: 6) {
                    Text("Yearlit")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
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
                        let activeCalendars = store.calendars.filter { !$0.isArchived }
                        // Use stable IDs to keep paging aligned when filtering.
                        ForEach(activeCalendars, id: \.id) { calendar in
                            CustomCalendarView(calendar: calendar)
                                .id(calendar.id.uuidString)
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
                                    position.scrollTo(id: newCalendar.id.uuidString)
                                    router.dismissScreen()
                                    addPositiveEvent(.createdCalendar)
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .onOpenURL { url in
                handleCalendarDeepLink(url)
            }
            .onReceive(store.$calendars) { _ in
                if let pendingCalendarId {
                    scrollToCalendarIfAvailable(pendingCalendarId)
                }
            }

            .onAppear {
                Purchases.shared.getCustomerInfo { info, _ in
                    customerInfo = info
                }
            }
            .onChange(of: whatsNewManager.pendingRelease?.version) { _ in
                guard let release = whatsNewManager.takePendingRelease() else { return }
                router.showScreen(.sheet) { _ in
                    WhatsNewSheetView(release: release) {
                        whatsNewManager.markSeen(release)
                        router.dismissScreen()
                    }
                    .presentationDetents([.fraction(0.92)])
                    .presentationDragIndicator(.visible)
                }
            }
        }
        .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
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

    private func scrollToCalendarIfAvailable(_ id: String) {
        guard store.calendars.contains(where: { $0.id.uuidString == id && !$0.isArchived }) else { return }
        pendingCalendarId = nil
        position.scrollTo(id: id)
    }
}
