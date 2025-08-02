import SharedModels
import SwiftData
import SwiftUI

struct CalendarsOverview: View {
  @ObservedObject var store: CustomCalendarStore
  @Binding var selectedIndex: Int
  @Environment(\.dismiss) private var dismiss
  @State private var isReorderActive = false
  @State private var showingAddCalendarSheet = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        HStack {
          Text("Calendars")
            .font(.system(size: 32, design: .monospaced))
            .fontWeight(.bold)
            .foregroundColor(Color("text-primary"))

          Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)

        CustomSeparator()
        ScrollView {
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
              }

              Spacer()

              Text("Track your year mood")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color("text-tertiary"))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
            .background(Color("surface-secondary"))
            .cornerRadius(12)
            .aspectRatio(1.4, contentMode: .fit)
            .onTapGesture {
              selectedIndex = 0
              dismiss()
            }.opacity(isReorderActive ? 0.5 : 1)

            // Custom Calendar Cards
            ForEach(
              Array(store.calendars.sorted { $0.order < $1.order }.enumerated()), id: \.element.id
            ) { index, calendar in
              CalendarsOverviewsItem(
                calendar: calendar, selectedIndex: $selectedIndex, store: store,
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
              showingAddCalendarSheet = true
            }
          }
          .padding()
          .animation(.spring(), value: store.calendars.map { $0.order })
        }
      }
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
    .sheet(isPresented: $showingAddCalendarSheet) {
      NavigationStack {
        CreateCalendarView { newCalendar in
          store.addCalendar(newCalendar)
          showingAddCalendarSheet = false
        }
        .background(Color("surface-muted"))
      }
    }
  }
}
