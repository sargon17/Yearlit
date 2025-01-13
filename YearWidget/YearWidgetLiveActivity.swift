//
//  YearWidgetLiveActivity.swift
//  YearWidget
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct YearWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct YearWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: YearWidgetAttributes.self) { context in
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

extension YearWidgetAttributes {
    fileprivate static var preview: YearWidgetAttributes {
        YearWidgetAttributes(name: "World")
    }
}

extension YearWidgetAttributes.ContentState {
    fileprivate static var smiley: YearWidgetAttributes.ContentState {
        YearWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: YearWidgetAttributes.ContentState {
         YearWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: YearWidgetAttributes.preview) {
   YearWidgetLiveActivity()
} contentStates: {
    YearWidgetAttributes.ContentState.smiley
    YearWidgetAttributes.ContentState.starEyes
}
