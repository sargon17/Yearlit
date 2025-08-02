import SharedModels

func getMaxCount(calendar: CustomCalendar) -> Int {
  let maxCount = calendar.entries.values.map { $0.count }.max() ?? 1
  return max(maxCount, 1)
}
