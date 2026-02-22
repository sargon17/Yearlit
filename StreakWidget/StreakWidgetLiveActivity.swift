//
//  StreakWidgetLiveActivity.swift
//  StreakWidget
//
//  Created by Mykhaylo Tymofyeyev  on 10/01/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct StreakWidgetAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    /// Fixed non-changing properties about your activity go here!
    var name: String
}

struct StreakWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StreakWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

private extension StreakWidgetAttributes {
    static var preview: StreakWidgetAttributes {
        StreakWidgetAttributes(name: "World")
    }
}

private extension StreakWidgetAttributes.ContentState {
    static var smiley: StreakWidgetAttributes.ContentState {
        StreakWidgetAttributes.ContentState(emoji: "😀")
    }

    static var starEyes: StreakWidgetAttributes.ContentState {
        StreakWidgetAttributes.ContentState(emoji: "🤩")
    }
}

#Preview("Notification", as: .content, using: StreakWidgetAttributes.preview) {
    StreakWidgetLiveActivity()
} contentStates: {
    StreakWidgetAttributes.ContentState.smiley
    StreakWidgetAttributes.ContentState.starEyes
}
