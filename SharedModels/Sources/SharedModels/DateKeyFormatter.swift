import Foundation

public enum DayKeyFormatter {
    private static let threadDictionaryKey = "SharedModels.DayKeyFormatter.shared"

    public static var shared: DateFormatter {
        if let formatter = Thread.current.threadDictionary[threadDictionaryKey] as? DateFormatter {
            return formatter
        }

        let formatter = makeFormatter()
        Thread.current.threadDictionary[threadDictionaryKey] = formatter
        return formatter
    }

    private static func makeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
