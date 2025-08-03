import SharedModels
import SwiftUI

struct CounterEntryModule: View {
  let calendar: CustomCalendar
  @Binding var entryCount: Int

  var body: some View {
    VStack {
      CustomSection(label: "Count") {
        HStack(spacing: 2) {
          Button(action: {
            withAnimation(.snappy) {
              entryCount = max(0, entryCount - 1)
            }
            Task {
              await hapticFeedback(.rigid)
            }
          }) {
            Image(systemName: "minus")
              .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: .greatestFiniteMagnitude)
              .padding()
          }
          .sameLevelBorder()

          Text("\(entryCount)")
            .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: .greatestFiniteMagnitude)
            .inputStyle(color: Color(calendar.color))
            .contentTransition(.numericText())

          Button(action: {
            withAnimation(.snappy) {
              entryCount += 1
            }
            Task {
              await hapticFeedback(.rigid)
            }
          }) {
            Image(systemName: "plus")
              .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: .greatestFiniteMagnitude)
              .padding()
          }
          .sameLevelBorder()
        }
        .padding(2)
        .outerSameLevelShadow()
        .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: 100)
        .accentColor(Color(calendar.color))
      }

      Spacer()
    }
  }
}
