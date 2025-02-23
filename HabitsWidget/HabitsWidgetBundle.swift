//
//  HabitsWidgetBundle.swift
//  HabitsWidget
//
//  Created by Mykhaylo Tymofyeyev  on 23/02/25.
//

import WidgetKit
import SwiftUI

@main
struct HabitsWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitsWidget()
        HabitsWidgetControl()
    }
}
