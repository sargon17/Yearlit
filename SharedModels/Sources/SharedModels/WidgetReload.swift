import Foundation

#if os(iOS)
    import WidgetKit
#endif

public enum WidgetReload {
    private static let queue = DispatchQueue(label: "WidgetReload.debounce")
    private static var pendingWorkItem: DispatchWorkItem?

    public static func scheduleAllTimelinesReload(debounce: TimeInterval = 0.5) {
        #if os(iOS)
            queue.async {
                pendingWorkItem?.cancel()
                let workItem = DispatchWorkItem {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                pendingWorkItem = workItem
                queue.asyncAfter(deadline: .now() + debounce, execute: workItem)
            }
        #endif
    }
}
