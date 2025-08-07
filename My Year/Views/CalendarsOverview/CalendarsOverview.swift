import SharedModels
import SwiftData
import SwiftUI
import SwiftfulRouting

struct CalendarsOverview: View {
  @ObservedObject var store: CustomCalendarStore
  @ObservedObject var valuationStore: ValuationStore
  @Binding var selectedIndex: Int
  @Environment(\.dismiss) private var dismiss
  @State private var isReorderActive = false

  @Environment(\.router) private var router

  var body: some View {

    ScrollView {
      CustomSeparator()
      LazyVGrid(
        columns: [
          GridItem(.flexible()),
          GridItem(.flexible())
        ], spacing: 8
      ) {
        // Year Grid Card
        VStack(alignment: .leading, spacing: 12) {
          HStack(alignment: .firstTextBaseline) {
            Rectangle()
              .fill(Color("mood-excellent"))
              .frame(width: 12, height: 12)
              .cornerRadius(3)

            Text("Year")
              .font(.system(size: 18, design: .monospaced))
              .fontWeight(.bold)
              .foregroundColor(Color("text-primary"))
              .lineLimit(2)
              .minimumScaleFactor(0.5)
              .multilineTextAlignment(.leading)

            Spacer()
          }

          Spacer()

          Text("Track your year mood")
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(Color("text-tertiary"))
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.leading)
        }
        .cardStyle()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onTapGesture {
          selectedIndex = 0
          dismiss()
        }.opacity(isReorderActive ? 0.5 : 1)

        // Custom Calendar Cards
        ForEach(
          Array(store.calendars.sorted { $0.order < $1.order }.enumerated()), id: \.element.id
        ) { index, calendar in
          CalendarsOverviewsItem(
            calendar: store.calendars[index],
            selectedIndex: $selectedIndex,
            store: store,
            isReorderActive: $isReorderActive
          )
          .onTapGesture {
            selectedIndex = index + 2
            dismiss()
          }
        }

        // Add Calendar Button
        VStack {
          Spacer()
          VStack(spacing: 16) {
            Image(systemName: "plus")
              .font(.system(size: 42))
              .foregroundStyle(Color("text-secondary"))
            Text("Add Calendar")
              .font(.headline)
              .foregroundColor(Color("text-primary"))
          }
          Spacer()
        }
        .onTapGesture {
          router.showScreen(.sheet) { _ in
            CreateCalendarView { newCalendar in
              store.addCalendar(newCalendar)
              selectedIndex = store.calendars.count
              router.dismissScreen()
            }
          }
        }
      }
      .padding()
      .animation(.spring(), value: store.calendars.map { $0.order })
    }
    .navigationTitle("Calendars")
    .background(Color("surface-muted"))
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: { isReorderActive.toggle() }) {
          Image(systemName: "arrow.up.arrow.down")
            .resizable()
            .frame(width: 16, height: 16)
            .foregroundColor(Color("text-tertiary"))

        }
      }
    }
  }
}
