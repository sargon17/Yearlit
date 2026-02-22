import SharedModels
import SwiftfulRouting
import SwiftUI

struct StackSection: View {
    @StateObject private var store = HabitStackStore.shared

    var body: some View {
        HabitStacksHome(store: store)
            .page()
    }
}
