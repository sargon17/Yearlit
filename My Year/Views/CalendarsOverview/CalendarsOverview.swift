import SharedModels
import SwiftData
import SwiftUI
import SwiftfulRouting

struct CalendarsOverview: View {
  @ObservedObject var store: CustomCalendarStore
  @ObservedObject var valuationStore: ValuationStore
  @Binding var scrollPosition: ScrollPosition
  @Environment(\.dismiss) private var dismiss

  @Environment(\.router) private var router

  var body: some View {

    ScrollView {
      VStack(spacing: 0) {
        CustomSeparator()
        LazyVStack(spacing: 12) {
          // Custom Calendar Cards
          ForEach(
            Array(store.calendars.sorted { $0.order < $1.order }.enumerated()), id: \.element.id
          ) { index, calendar in
          CalendarsOverviewsItem(
            calendar: store.calendars[index],
            store: store
          )
            .onTapGesture {
              dismiss()
              scrollPosition.scrollTo(id: index.description)
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
                scrollPosition.scrollTo(id: store.calendars.count)

                router.dismissScreen()

                addPositiveEvent(.createdCalendar)
              }
            }
          }
        }
        .padding()
        .animation(.spring(), value: store.calendars.map { $0.order })
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    }
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("Calendars")
  }
}
