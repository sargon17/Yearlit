import SharedModels
import SwiftUI

struct OverviewDerivedSnapshot: Codable {
    let statsBundleSnapshot: StatsBundleSnapshot
    let zByDay: [Double]

    var statsBundle: StatsBundle {
        statsBundleSnapshot.toBundle()
    }
}

struct OverviewDerivedInput: Hashable {
    let year: Int
    let dataVersion: Int
    let daySeedKey: String
    let timeZoneIdentifier: String
}

func makeOverviewDerivedInput(year: Int, dataVersion: Int, today: Date) -> OverviewDerivedInput {
    OverviewDerivedInput(
        year: year,
        dataVersion: dataVersion,
        daySeedKey: dayKey(for: LocalDayCalendar.startOfDay(for: today)),
        timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier
    )
}

func makeOverviewDerivedCacheKey(_ input: OverviewDerivedInput) -> CacheKey {
    CacheKey(
        scope: .overviewDerivedSnapshot,
        identifier: "v1|\(input.year)|\(input.dataVersion)|\(input.daySeedKey)|\(input.timeZoneIdentifier)"
    )
}

func computeOverviewDerivedSnapshot(
    calendars: [CustomCalendar],
    year: Int,
    dates: [Date],
    todayLocal: Date,
    currentPeriodReferenceDate: Date?
) -> OverviewDerivedSnapshot {
    var cal = Calendar(identifier: .gregorian)
    cal.locale = Locale(identifier: "en_US_POSIX")
    cal.timeZone = .autoupdatingCurrent

    let entriesByCalendarByBucket = buildEntriesByCalendarByBucket(calendars: calendars)
    let q75ByCalendar = counterPercentile75ByCalendar(calendars: calendars)
    let (totalCount, perDayTotal) = aggregateCounts(cal: cal, calendars: calendars)
    let maxCount = perDayTotal.values.max() ?? 0

    let (anySuccessByDay, dayMeanZMap) = buildDailyMaps(
        cal: cal,
        year: year,
        todayLocal: todayLocal,
        calendars: calendars,
        entriesByCalendarByBucket: entriesByCalendarByBucket,
        q75ByCalendar: q75ByCalendar
    )

    let zByDay = dates.map { date in
        guard date <= todayLocal else { return 0.0 }
        return dayMeanZMap[date] ?? 0.0
    }

    let allTimeSuccessDays = buildAllTimeSuccessDays(
        cal: cal,
        todayLocal: todayLocal,
        calendars: calendars
    )
    let activeDays = allTimeSuccessDays.count
    let (longestStreak, currentStreak) = computeStreaks(cal: cal, successDays: allTimeSuccessDays, today: todayLocal)

    let currentPeriodCount = currentPeriodReferenceDate.map { referenceDate in
        calendars.reduce(0) { partial, calendar in
            let bucketDate = calendar.bucketDate(for: referenceDate)
            return partial + (entriesByCalendarByBucket[calendar.id]?[bucketDate]?.count ?? 0)
        }
    }

    let (cr30, avg7, avg30) = computeRollingStats(
        cal: cal,
        todayLocal: todayLocal,
        anySuccessByDay: anySuccessByDay,
        dayMeanZ: dayMeanZMap
    )

    let (weekdayRates, bestWD) = computeWeekdayRates(cal: cal, dayMeanZ: dayMeanZMap)
    let monthlyRates = computeMonthlyRates(cal: cal, year: year, todayLocal: todayLocal, dayMeanZ: dayMeanZMap)
    let volatility = computeWeeklyVolatility(cal: cal, todayLocal: todayLocal, anySuccessByDay: anySuccessByDay)

    let statsBundle = StatsBundle(
        basic: CalendarStats(
            activeDays: activeDays,
            totalCount: totalCount,
            maxCount: maxCount,
            longestStreak: longestStreak,
            currentStreak: currentStreak
        ),
        completionRateTrailingLongWindow: cr30,
        bestWeekday: bestWD?.day,
        weekdayRates: weekdayRates,
        monthlyRates: monthlyRates,
        averageProgressTrailingShortWindow: avg7,
        averageProgressTrailingLongWindow: avg30,
        volatilityStd: volatility,
        currentPeriodCount: currentPeriodCount
    )

    return OverviewDerivedSnapshot(
        statsBundleSnapshot: StatsBundleSnapshot(bundle: statsBundle),
        zByDay: zByDay
    )
}

actor OverviewDerivedSnapshotService {
    static let shared = OverviewDerivedSnapshotService()
    private var inFlight: [CacheKey: Task<OverviewDerivedSnapshot?, Never>] = [:]

    func snapshot(
        storeSnapshot: CustomCalendarStoreSnapshot,
        year: Int,
        today: Date
    ) async -> OverviewDerivedSnapshot? {
        let input = makeOverviewDerivedInput(year: year, dataVersion: storeSnapshot.dataVersion, today: today)
        let cacheKey = makeOverviewDerivedCacheKey(input)

        if let cached: OverviewDerivedSnapshot = CacheStore.shared.get(cacheKey) {
            return cached
        }

        if let cached: OverviewDerivedSnapshot = CacheStore.shared.loadDisk(cacheKey) {
            CacheStore.shared.set(cacheKey, value: cached)
            return cached
        }

        guard !storeSnapshot.isLoading else { return nil }
        if let task = inFlight[cacheKey] {
            return await task.value
        }

        let calendars = storeSnapshot.calendars
        let dates = getYearDatesArray(for: year)
        let currentPeriodReferenceDate = dates.first { Calendar.current.isDate($0, inSameDayAs: today) }

        let task = Task.detached(priority: .userInitiated) { () -> OverviewDerivedSnapshot? in
            computeOverviewDerivedSnapshot(
                calendars: calendars,
                year: year,
                dates: dates,
                todayLocal: today,
                currentPeriodReferenceDate: currentPeriodReferenceDate
            )
        }

        inFlight[cacheKey] = task
        let derived = await task.value
        inFlight[cacheKey] = nil

        if let derived {
            CacheStore.shared.set(cacheKey, value: derived)
            CacheStore.shared.saveDisk(cacheKey, value: derived)
        }
        return derived
    }
}
