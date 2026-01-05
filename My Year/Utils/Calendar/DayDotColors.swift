import Garnish
import SwiftUI

func inactiveDayColor() -> Color {
  GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.04)
}

func activeDayColor() -> Color {
  GarnishColor.blend(.surfaceMuted, with: .textPrimary, ratio: 0.12)
}
