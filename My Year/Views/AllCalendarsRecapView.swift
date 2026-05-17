import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftfulRouting
import SwiftUI

struct AllCalendarsRecapView: View {
    @ObservedObject private var store: CustomCalendarStore = .shared
    @ObservedObject private var valuationStore: ValuationStore = .shared

    @Environment(\.router) private var router
    @Environment(\.colorScheme) private var colorScheme

    @State private var customerInfo: CustomerInfo?
    @State private var isPaywallPresented: Bool = false
    @State private var statsBundle: StatsBundle? = nil
    @State private var showingYearPicker: Bool = false
    @State private var tempSelectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var statsRefreshToken = UUID()
    @State private var lastObservedDataVersion: Int = 0
    @State private var hasTrackedView = false

    private let availableYears: [Int] = {
        let currentYear: Int = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 10) ... currentYear).reversed()
    }()

    var body: some View {
        let snapshot = store.snapshot
        let selectedYear = valuationStore.selectedYear
        let dataVersion = snapshot.dataVersion
        let today = Date()
        let daySeedKey = dayKey(for: LocalDayCalendar.startOfDay(for: today))
        let hydrationKey = snapshot.isLoading ? "loading" : "hydrated"
        let statsTaskId = [
            "\(selectedYear)",
            "\(dataVersion)",
            hydrationKey,
            daySeedKey,
            statsRefreshToken.uuidString
        ].joined(separator: "|")

        ScrollView {
            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    HStack(alignment: .center, spacing: 6) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("Overview")
                                    .font(AppFont.mono(36))
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.5)
                                    .foregroundColor(Color("text-primary"))
                                    .fontWeight(.black)
                                    .padding(.top)
                                Spacer()
                            }
                            HStack(spacing: 4) {
                                Button(action: { showingYearPicker = true }) {
                                    Text("\(valuationStore.year.description)")
                                        .font(AppFont.mono(12))
                                        .foregroundColor(Color("text-tertiary"))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    CustomSeparator()
                }

                OverallGridView(
                    accentColor: Color("qs-emerald"),
                    store: store,
                    year: selectedYear
                )
                .frame(height: UIScreen.main.bounds.height * 0.55)

                if let bundle = statsBundle {
                    CalendarStatisticsView(
                        stats: bundle.basic,
                        accentColor: Color("qs-emerald"),
                        currentPeriodCount: bundle.currentPeriodCount,
                        unit: nil,
                        currencySymbol: nil,
                        completionRateTrailingLongWindow: bundle.completionRateTrailingLongWindow,
                        bestWeekday: bundle.bestWeekday,
                        weekdayRates: bundle.weekdayRates,
                        monthlyRates: bundle.monthlyRates,
                        averageProgressTrailingShortWindow: bundle.averageProgressTrailingShortWindow,
                        averageProgressTrailingLongWindow: bundle.averageProgressTrailingLongWindow,
                        volatilityStdDev: bundle.volatilityStd,
                        isPremium: isPremium(customerInfo: customerInfo),
                        onUpgrade: { isPaywallPresented = true }
                    )
                    .id(colorScheme)
                    .padding(.top, 20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView()
        }
        .sheet(isPresented: $showingYearPicker) {
            NavigationStack {
                VStack {
                    Picker("Select Year", selection: $tempSelectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text(year.description)
                                .foregroundColor(Color("text-primary"))
                                .tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                .navigationTitle("Select Year")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            tempSelectedYear = valuationStore.selectedYear
                            showingYearPicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            valuationStore.selectedYear = tempSelectedYear
                            showingYearPicker = false
                        }
                    }
                }
                .onAppear {
                    tempSelectedYear = valuationStore.selectedYear
                }
            }
            .presentationDetents([.height(280)])
        }
        .onAppear {
            Purchases.shared.getCustomerInfo { info, _ in
                self.customerInfo = info
            }
            guard !hasTrackedView else { return }
            hasTrackedView = true
            Analytics.shared.track(.recapViewViewed)
            if lastObservedDataVersion != snapshot.dataVersion {
                lastObservedDataVersion = snapshot.dataVersion
                statsRefreshToken = UUID()
            }
        }
        .onChange(of: snapshot.dataVersion) { _, newValue in
            lastObservedDataVersion = newValue
            statsBundle = nil
            statsRefreshToken = UUID()
        }
        .onChange(of: snapshot.isLoading) { _, isLoading in
            if !isLoading {
                statsBundle = nil
                statsRefreshToken = UUID()
            }
        }
        .task(id: statsTaskId) {
            guard !snapshot.isLoading else { return }
            let token = statsRefreshToken
            let currentSnapshot = await MainActor.run { store.snapshot }
            guard currentSnapshot.dataVersion == dataVersion, !currentSnapshot.isLoading else { return }
            if let derived = await OverviewDerivedSnapshotService.shared.snapshot(
                storeSnapshot: currentSnapshot,
                year: selectedYear,
                today: today
            ), token == statsRefreshToken, !store.snapshot.isLoading {
                statsBundle = derived.statsBundle
            }
        }
    }
}

#Preview {
    AllCalendarsRecapView()
}
