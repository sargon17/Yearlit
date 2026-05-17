import Combine
import Foundation
import SharedModels

@MainActor
final class TimelinePreferenceManager: ObservableObject {
  static let shared = TimelinePreferenceManager()

  @Published private(set) var mode: CalendarTimelineMode

  private init() {
    mode = TimelinePreferenceStore.mode()
  }

  func setMode(_ mode: CalendarTimelineMode) {
    self.mode = mode
    TimelinePreferenceStore.setMode(mode)
    WidgetReload.scheduleHabitWidgetsReload()
  }

  func refresh() {
    mode = TimelinePreferenceStore.mode()
  }
}
