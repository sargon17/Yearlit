import Testing

@testable import SharedModels

struct MosaicChartTests {
  @Test func zeroTotalCountProducesZeroWidth() {
    let chart = MosaicChart(
      dayTypesQuantity: [
        .notEvaluated: 0,
        .future: 0
      ],
      visualizationType: .full
    )

    #expect(chart.calculateWidth(for: (.notEvaluated, 0), availableWidth: 320) == 0)
  }
}
