@testable import My_Year
import Testing

struct CompactStatsNumberTests {
  @Test func leavesSmallNumbersUnchanged() {
    #expect(compactStatsNumber(0) == "0")
    #expect(compactStatsNumber(999) == "999")
  }

  @Test func formatsThousandsMillionsAndBillions() {
    #expect(compactStatsNumber(1_000) == "1K")
    #expect(compactStatsNumber(1_250) == "1.3K")
    #expect(compactStatsNumber(12_340) == "12.3K")
    #expect(compactStatsNumber(123_400) == "123K")
    #expect(compactStatsNumber(1_250_000) == "1.3M")
    #expect(compactStatsNumber(1_250_000_000) == "1.3B")
  }

  @Test func promotesRoundedValuesToNextSuffix() {
    #expect(compactStatsNumber(999_950) == "1M")
  }
}
