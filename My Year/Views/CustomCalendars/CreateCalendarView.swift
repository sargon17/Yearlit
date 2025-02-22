import RevenueCatUI
import SharedModels
import SwiftUI

struct CreateCalendarView: View {
  @Environment(\.dismiss) private var dismiss
  let onCreate: (CustomCalendar) -> Void

  @State private var name = ""
  @State private var selectedColor = "mood-good"
  @State private var trackingType: TrackingType = .binary
  @State private var dailyTarget = 2
  @State private var recurringReminderEnabled: Bool = false
  @State private var reminderTime: Date = Date()

  private let colors = [
    "mood-terrible",
    "mood-bad",
    "mood-neutral",
    "mood-good",
    "mood-excellent",
  ]

  var body: some View {
    Form {
      Section {
        TextField("Calendar Name", text: $name)
          .foregroundColor(Color("text-primary"))
          .fontWeight(.bold)
      }
      .listRowBackground(Color("surface-primary"))

      Section {
        Picker("Tracking Type", selection: $trackingType) {
          Text("Once a day").tag(TrackingType.binary)
          Text("Multiple times (unlimited)").tag(TrackingType.counter)
          Text("Multiple times (with target)").tag(TrackingType.multipleDaily)
        }

        if trackingType == .multipleDaily {
          Stepper("Daily Target: \(dailyTarget)", value: $dailyTarget, in: 1...10)
        }
      }
      .listRowBackground(Color("surface-primary"))

      Section {
        Toggle("Recurring Reminder", isOn: $recurringReminderEnabled)
        if recurringReminderEnabled {
          DatePicker(
            "Reminder Time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
        }
      }
      .listRowBackground(Color("surface-primary"))

      Section {
        HStack {
          ForEach(colors, id: \.self) { color in
            Circle()
              .fill(Color(color))
              .frame(width: 30, height: 30)
              .overlay(
                Circle()
                  .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
              )
              .onTapGesture {
                selectedColor = color
              }
          }
        }
      } header: {
        Text("Color")
      }
      .listRowBackground(Color("surface-primary"))
    }
    .scrollContentBackground(.hidden)
    .background(Color("surface-muted"))
    .navigationTitle("New Calendar")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Create") {
          let calendar = CustomCalendar(
            name: name,
            color: selectedColor,
            trackingType: trackingType,
            dailyTarget: dailyTarget,
            recurringReminderEnabled: recurringReminderEnabled,
            reminderTime: recurringReminderEnabled ? reminderTime : nil
          )
          onCreate(calendar)
        }
        .disabled(name.isEmpty)
      }
    }
  }
}
