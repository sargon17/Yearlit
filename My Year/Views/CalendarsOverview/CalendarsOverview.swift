import SharedModels
import SwiftData
import SwiftUI
import SwiftfulRouting

struct CalendarsOverview: View {
  @AppStorage("isMoodTrackingEnabled") var isMoodTrackingEnabled: Bool = false

  @ObservedObject var store: CustomCalendarStore
  @ObservedObject var valuationStore: ValuationStore
  @Binding var scrollPosition: ScrollPosition
  @Environment(\.dismiss) private var dismiss
  @State private var isReorderActive = false

  @Environment(\.router) private var router

  var body: some View {

    ScrollView {
      VStack(spacing: 0) {
        CustomSeparator()
        LazyVGrid(
          columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
          ], spacing: 8
        ) {
        // Year Grid Card
        if isMoodTrackingEnabled {
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
            scrollPosition.scrollTo(id: "mood")
            dismiss()
          }.opacity(isReorderActive ? 0.5 : 1)
        }

        // Custom Calendar Cards
        ForEach(
          Array(store.calendars.sorted { $0.order < $1.order }.enumerated()), id: \.element.id
        ) { index, calendar in
          CalendarsOverviewsItem(
            calendar: store.calendars[index],
            store: store,
            isReorderActive: $isReorderActive
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
