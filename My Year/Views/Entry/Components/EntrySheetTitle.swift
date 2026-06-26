import SwiftUI

extension DayEntryEditSheet {
  struct Title: View {
    let title: String

    var body: some View {
      Text(title)
        .font(.headline)
        .padding()
    }
  }
}
