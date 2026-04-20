import SharedModels
import SwiftfulRouting
import SwiftUI

struct ArchivedCalendarsSheet: View {
    @ObservedObject var store: CustomCalendarStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.router) private var router

    private var archivedCalendars: [CustomCalendar] {
        store.snapshot.archivedCalendars
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    CustomSeparator()
                        .padding(.horizontal, -16)
                    Text("Tap a calendar to unarchive it and bring it back to your boards.")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    if archivedCalendars.isEmpty {
                        Text("No archived calendars yet.")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(archivedCalendars, id: \.id) { calendar in
                                CalendarsOverviewsItem(calendar: calendar, store: store)
                                    .opacity(0.7)
                                    .onTapGesture {
                                        var updatedCalendar = calendar
                                        updatedCalendar.isArchived = false
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            store.updateCalendar(updatedCalendar)
                                        }
                                    }
                                    .transition(.opacity.combined(with: .scale(scale: 0.98)))

                                CustomSeparator()
                                    .padding(.horizontal, -16)
                            }
                        }
                        .padding()
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: archivedCalendars.map(\.id))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
            }
            .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
            .navigationTitle("Archived Calendars")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ArchivedCalendarsSheet(store: .shared)
}
