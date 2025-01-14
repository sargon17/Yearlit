//
//  YearEvaluationWidgetBundle.swift
//  YearEvaluationWidget
//
//  Created by Mykhaylo Tymofyeyev  on 14/01/25.
//

import WidgetKit
import SwiftUI

@main
struct YearEvaluationWidgetBundle: WidgetBundle {
    var body: some Widget {
        YearEvaluationWidget()
        YearEvaluationWidgetControl()
        YearEvaluationWidgetLiveActivity()
    }
}
