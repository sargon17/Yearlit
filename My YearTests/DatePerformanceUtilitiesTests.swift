import Foundation
@testable import My_Year
import Testing

struct DatePerformanceUtilitiesTests {
    @Test func dayKeyIsStableUnderConcurrentAccess() async {
        let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 4, day: 19))!
        let expected = dayKey(for: date)

        let results = await withTaskGroup(of: String.self, returning: [String].self) { group in
            for _ in 0 ..< 128 {
                group.addTask {
                    dayKey(for: date)
                }
            }

            var values: [String] = []
            for await value in group {
                values.append(value)
            }
            return values
        }

        #expect(results.count == 128)
        #expect(results.allSatisfy { $0 == expected })
    }

    @Test func yearDatesArrayMatchesLeapYearCounts() {
        #expect(getYearDatesArray(for: 2024).count == 366)
        #expect(getYearDatesArray(for: 2025).count == 365)
    }
}
