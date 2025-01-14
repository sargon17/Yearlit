//
//  YearEvaluationWidgetLiveActivity.swift
//  YearEvaluationWidget
//
//  Created by Mykhaylo Tymofyeyev  on 14/01/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct YearEvaluationWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct YearEvaluationWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: YearEvaluationWidgetAttributes.self) { context in
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

extension YearEvaluationWidgetAttributes {
    fileprivate static var preview: YearEvaluationWidgetAttributes {
        YearEvaluationWidgetAttributes(name: "World")
    }
}

extension YearEvaluationWidgetAttributes.ContentState {
    fileprivate static var smiley: YearEvaluationWidgetAttributes.ContentState {
        YearEvaluationWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: YearEvaluationWidgetAttributes.ContentState {
         YearEvaluationWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: YearEvaluationWidgetAttributes.preview) {
   YearEvaluationWidgetLiveActivity()
} contentStates: {
    YearEvaluationWidgetAttributes.ContentState.smiley
    YearEvaluationWidgetAttributes.ContentState.starEyes
}
