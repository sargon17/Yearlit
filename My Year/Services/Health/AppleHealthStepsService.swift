import Foundation
import HealthKit
import SharedModels

enum AppleHealthStepsServiceError: LocalizedError {
  case unavailable
  case missingStepType
  case noReadableStepData

  var errorDescription: String? {
    switch self {
    case .unavailable:
      return String(localized: "Apple Health is not available on this device.")
    case .missingStepType:
      return String(localized: "Apple Health steps are not available on this device.")
    case .noReadableStepData:
      return String(localized: "No readable Apple Health step data was returned.")
    }
  }
}

struct AppleHealthStepsService {
  private let healthStore = HKHealthStore()

  func requestAuthorization() async throws {
    guard HKHealthStore.isHealthDataAvailable() else {
      throw AppleHealthStepsServiceError.unavailable
    }
    guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
      throw AppleHealthStepsServiceError.missingStepType
    }

    try await healthStore.requestAuthorization(toShare: [], read: [stepType])
  }

  func currentYearStepCounts() async throws -> [Date: Int] {
    guard HKHealthStore.isHealthDataAvailable() else {
      throw AppleHealthStepsServiceError.unavailable
    }
    guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
      throw AppleHealthStepsServiceError.missingStepType
    }

    let calendar = LocalDayCalendar.calendar
    let today = LocalDayCalendar.startOfDay(for: Date())
    let year = calendar.component(.year, from: today)
    guard
      let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
      let end = calendar.date(byAdding: .day, value: 1, to: today)
    else {
      return [:]
    }

    let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate])
    let interval = DateComponents(day: 1)

    return try await withCheckedThrowingContinuation { continuation in
      let query = HKStatisticsCollectionQuery(
        quantityType: stepType,
        quantitySamplePredicate: predicate,
        options: .cumulativeSum,
        anchorDate: start,
        intervalComponents: interval
      )

      query.initialResultsHandler = { _, collection, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }

        guard let collection else {
          continuation.resume(returning: [:])
          return
        }

        var counts: [Date: Int] = [:]
        collection.enumerateStatistics(from: start, to: end) { statistics, _ in
          let count = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
          let roundedCount = Int(count.rounded())
          if roundedCount > 0 {
            counts[LocalDayCalendar.startOfDay(for: statistics.startDate)] = roundedCount
          }
        }
        continuation.resume(returning: counts)
      }

      healthStore.execute(query)
    }
  }
}
