import SharedModels
import SwiftData
import SwiftfulRouting
import SwiftUI

struct CalendarsOverview: View {
    @ObservedObject var store: CustomCalendarStore
    @ObservedObject var valuationStore: ValuationStore
    @Binding var scrollPosition: ScrollPosition
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.editMode) private var editMode
    @State private var showingArchivedCalendars = false
    @State private var showingJournalEntries = false

    @Environment(\.router) private var router

    var body: some View {
        let activeCalendars = store.snapshot.activeCalendars

        List {
            Section {
                // CustomSeparator()
                //   .padding(.horizontal, -16)

                ForEach(activeCalendars, id: \.id) { calendar in
                    VStack(spacing: 0) {
                        CalendarsOverviewsItem(calendar: calendar, store: store)
                            .onTapGesture {
                                guard editMode?.wrappedValue.isEditing != true else { return }
                                dismiss()
                                scrollPosition.scrollTo(id: calendar.id.uuidString)
                            }
                            .padding(.all, 16)

                        CustomSeparator()
                            .padding(.horizontal, -16)
                    }
                    .listRowInsets(.init())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onMove(perform: moveCalendars)
            }

            Section {
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
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }.padding(.vertical, 32)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
        .navigationTitle("Calendars")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !activeCalendars.isEmpty {
                    EditButton()
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showingJournalEntries = true }) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 12))
                        .foregroundColor(Color("text-tertiary"))
                }

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
        .sheet(isPresented: $showingJournalEntries) {
            JournalEntriesSheet(valuationStore: valuationStore)
        }
    }

    private func moveCalendars(from offsets: IndexSet, to destination: Int) {
        store.moveActiveCalendars(fromOffsets: offsets, toOffset: destination)
    }
}
