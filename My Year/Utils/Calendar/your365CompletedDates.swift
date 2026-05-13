import SharedModels

func your365CompletedDates(for calendar: CustomCalendar) -> Set<Date> {
    Set(
        calendar.entries.values.compactMap { entry in
            switch calendar.trackingType {
            case .binary:
                return entry.completed ? entry.date : nil
            case .counter:
                return entry.count > 0 ? entry.date : nil
            case .multipleDaily:
                return entry.completed ? entry.date : nil
            }
        }
    )
}
