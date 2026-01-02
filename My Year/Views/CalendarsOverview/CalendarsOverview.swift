import SharedModels
import SwiftData
import SwiftUI
import SwiftfulRouting

struct CalendarsOverview: View {
  @ObservedObject var store: CustomCalendarStore
  @ObservedObject var valuationStore: ValuationStore
  @Binding var scrollPosition: ScrollPosition
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme
  @State private var showingArchivedCalendars = false

  @Environment(\.router) private var router

  var body: some View {

    ScrollView {
      VStack(spacing: 0) {
        CustomSeparator()
          .padding(.horizontal, -16)
        LazyVStack(spacing: 12) {
          // Custom Calendar Cards
          let sortedCalendars = store.calendars
            .filter { !$0.isArchived }
            .sorted { $0.order < $1.order }
          ForEach(sortedCalendars, id: \.id) { calendar in
            CalendarsOverviewsItem(calendar: calendar, store: store)
              .onTapGesture {
                dismiss()
                scrollPosition.scrollTo(id: calendar.id.uuidString)
              }

            CustomSeparator()
              .padding(.horizontal, -16)
          }

          // Add Calendar Button
          Button(action: {
            router.showScreen(.sheet) { _ in
              CreateCalendarView { newCalendar in
                store.addCalendar(newCalendar)
                scrollPosition.scrollTo(id: newCalendar.id.uuidString)

                router.dismissScreen()

                addPositiveEvent(.createdCalendar)
              }
            }
          }) {
            HStack(spacing: 12) {
              Image(systemName: "plus")
                .font(.system(size: 20))
                .foregroundStyle(Color("text-tertiary"))
              Text("Add Calendar")
                .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .fontWeight(.bold)
            .padding()
          }
          .sameLevelBorder()
          .foregroundStyle(.textTertiary)
          .padding(.all, 2)
          .background(getVoidColor(colorScheme: colorScheme))
          .padding(.top, 4)
        }
        .padding()
        .animation(.spring(), value: store.calendars.map { $0.order })
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    }
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("Calendars")
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: { showingArchivedCalendars = true }) {
          Image(systemName: "archivebox")
            .font(.system(size: 12))
            .foregroundColor(Color("text-tertiary"))
        }
      }
    }
    .sheet(isPresented: $showingArchivedCalendars) {
      ArchivedCalendarsSheet(store: store)
    }
  }
}
