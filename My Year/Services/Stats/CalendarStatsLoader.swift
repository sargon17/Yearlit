import Foundation
import SharedModels

@MainActor
final class CalendarStatsLoader: ObservableObject {
  @Published private(set) var bundle: StatsBundle?

  private var publishTask: Task<Void, Never>?
  private var computeTask: Task<StatsBundle, Never>?
  private var loadID = UUID()

  func load(
    calendar: CustomCalendar,
    year: Int,
    currentPeriodReferenceDate: Date?
  ) {
    publishTask?.cancel()
    computeTask?.cancel()
    bundle = nil

    let currentLoadID = UUID()
    loadID = currentLoadID

    let computeTask = Task.detached(priority: .userInitiated) {
      computeCalendarStatsBundle(
        calendar: calendar,
        year: year,
        todayLocal: Date(),
        currentPeriodReferenceDate: currentPeriodReferenceDate
      )
    }
    self.computeTask = computeTask

    publishTask = Task {
      let bundle = await computeTask.value

      guard !Task.isCancelled, !computeTask.isCancelled, self.loadID == currentLoadID else { return }
      self.bundle = bundle
      self.publishTask = nil
      self.computeTask = nil
    }
  }

  func cancel() {
    publishTask?.cancel()
    computeTask?.cancel()
    publishTask = nil
    computeTask = nil
  }
}
