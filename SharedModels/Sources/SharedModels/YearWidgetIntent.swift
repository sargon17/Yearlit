import AppIntents
import WidgetKit

public struct YearWidgetConfigurationIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource {
        "Year Widget"
    }

    public static var description: IntentDescription {
        "Show the year's progress."
    }

    @Parameter(title: "Visualization", default: .appDefault)
    public var visualizationStyle: WidgetGridStyleOption

    public init() {}
}
