@testable import My_Year
import Testing

struct DotFillRatioTests {
    @Test func counterRatioUsesRobustScaleSoOutliersDoNotHideNormalDays() {
        let counts = [1, 2, 2, 3, 3, 4, 100]

        #expect(counterDotFillRatio(count: 3, counts: counts) > 0.3)
        #expect(counterDotFillRatio(count: 100, counts: counts) == 1)
    }

    @Test func counterRatioStillShowsPositiveEntriesAboveMissedDayFill() {
        #expect(counterDotFillRatio(count: 1, counts: [1, 100]) == 0.35)
    }

    @Test func multipleDailyRatioEasesEarlyProgressWhileKeepingTargetFull() {
        let ratio = multipleDailyDotFillRatio(count: 1, dailyTarget: 10)

        #expect(ratio >= 0.35)
        #expect(multipleDailyDotFillRatio(count: 10, dailyTarget: 10) == 1)
        #expect(multipleDailyDotFillRatio(count: 20, dailyTarget: 10) == 1)
    }
}
