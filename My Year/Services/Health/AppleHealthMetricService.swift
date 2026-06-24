import Foundation
import HealthKit
import SharedModels

enum AppleHealthMetricServiceError: LocalizedError {
  case unavailable
  case missingQuantityType(AppleHealthMetric)
  case noReadableHealthData

  var errorDescription: String? {
    switch self {
    case .unavailable:
      return String(localized: "Apple Health is not available on this device.")
    case .missingQuantityType(let metric):
      return String(localized: "\(metric.title) is not available on this device.")
    case .noReadableHealthData:
      return String(localized: "No readable Apple Health data was returned.")
    }
  }
}

struct AppleHealthMetricService {
  private let healthStore = HKHealthStore()

  func requestAuthorization(for metric: AppleHealthMetric) async throws {
    try await requestAuthorization(for: [metric])
  }

  func requestAuthorization(for metrics: [AppleHealthMetric]) async throws {
    guard HKHealthStore.isHealthDataAvailable() else {
      throw AppleHealthMetricServiceError.unavailable
    }

    let quantityTypes = try metrics.map { metric in
      guard let quantityType = metric.quantityType else {
        throw AppleHealthMetricServiceError.missingQuantityType(metric)
      }
      return quantityType
    }

    try await healthStore.requestAuthorization(toShare: [], read: Set(quantityTypes))
  }

  func currentYearValues(for metric: AppleHealthMetric) async throws -> [Date: Int] {
    guard HKHealthStore.isHealthDataAvailable() else {
      throw AppleHealthMetricServiceError.unavailable
    }
    guard let quantityType = metric.quantityType else {
      throw AppleHealthMetricServiceError.missingQuantityType(metric)
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
        quantityType: quantityType,
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

        var values: [Date: Int] = [:]
        collection.enumerateStatistics(from: start, to: end) { statistics, _ in
          let value = statistics.sumQuantity()?.doubleValue(for: metric.healthKitUnit) ?? 0
          let roundedValue = Int(value.rounded())
          if roundedValue > 0 {
            values[LocalDayCalendar.startOfDay(for: statistics.startDate)] = roundedValue
          }
        }
        continuation.resume(returning: values)
      }

      healthStore.execute(query)
    }
  }
}

private extension AppleHealthMetric {
  var quantityIdentifier: HKQuantityTypeIdentifier {
    switch self {
    case .steps: return .stepCount
    case .activeEnergy: return .activeEnergyBurned
    case .exerciseMinutes: return .appleExerciseTime
    case .walkingRunningDistance: return .distanceWalkingRunning
    case .flightsClimbed: return .flightsClimbed
    }
  }

  var quantityType: HKQuantityType? {
    HKQuantityType.quantityType(forIdentifier: quantityIdentifier)
  }

  var healthKitUnit: HKUnit {
    switch self {
    case .steps: return .count()
    case .activeEnergy: return .kilocalorie()
    case .exerciseMinutes: return .minute()
    case .walkingRunningDistance: return .meter()
    case .flightsClimbed: return .count()
    }
  }
}
