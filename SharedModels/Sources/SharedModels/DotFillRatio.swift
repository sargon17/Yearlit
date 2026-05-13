import Foundation

private let minimumTrackedDotFillRatio = 0.35
private let robustDotScalePercentile = 0.9

public func counterDotFillRatio(count: Int, counts: [Int]) -> Double {
    guard count > 0 else { return 0 }

    let scale = robustDotScale(for: counts)
    let ratio = Double(count) / scale
    return min(1, max(minimumTrackedDotFillRatio, ratio))
}

public func multipleDailyDotFillRatio(count: Int, dailyTarget: Int) -> Double {
    guard count > 0 else { return 0 }

    let target = max(dailyTarget, 1)
    let progress = min(1, Double(count) / Double(target))
    let easedProgress = sqrt(progress)
    return min(1, max(minimumTrackedDotFillRatio, easedProgress))
}

private func robustDotScale(for counts: [Int]) -> Double {
    let positiveCounts = counts.filter { $0 > 0 }
    guard !positiveCounts.isEmpty else { return 1 }

    return max(1, percentile(positiveCounts, p: robustDotScalePercentile))
}

private func percentile(_ values: [Int], p: Double) -> Double {
    let sortedValues = values.sorted()
    guard !sortedValues.isEmpty else { return 1 }

    let position = max(0, min(Double(sortedValues.count - 1), p * Double(sortedValues.count - 1)))
    let lowerIndex = Int(floor(position))
    let upperIndex = Int(ceil(position))

    guard lowerIndex != upperIndex else {
        return Double(sortedValues[lowerIndex])
    }

    let weight = position - Double(lowerIndex)
    return Double(sortedValues[lowerIndex]) * (1 - weight) + Double(sortedValues[upperIndex]) * weight
}
