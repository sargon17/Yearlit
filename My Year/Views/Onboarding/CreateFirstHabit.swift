import Garnish
import SharedModels
import SwiftDate
import SwiftUI

struct CreateFirstHabit: View {
  let onNext: () -> Void
  @ObservedObject private var store = CustomCalendarStore.shared
  @Environment(\.colorScheme) var colorScheme

  @State var name = ""
  @State var recurringReminderEnabled = true
  @State private var reminderTime: Date = {
    var components = DateComponents()
    components.hour = 8
    components.minute = 30
    return Calendar.current.date(from: components) ?? Date()
  }()

  var disabled: Bool {
    return name.count > 2 ? false : true
  }

  func handleNext() {
    let calendar = CustomCalendar(
      name: name,
      color: "qs-orange",
      trackingType: .binary,
      dailyTarget: 1,
      recurringReminderEnabled: false,
      reminderTime: nil,
      unit: UnitOfMeasure.none,
      defaultRecordValue: 1,
      currencySymbol: nil
    )

    store.addCalendar(calendar)

    onNext()
  }

  var body: some View {
    OnboardingView.OnboardingSlide(onNext: handleNext, disabled: disabled, withSkip: true) {
      VStack(spacing: 12) {
        CustomSection(label: "Give it a name") {
          TextField(
            "",
            text: $name,
            prompt: Text("Daily Training").foregroundColor(.white.opacity(0.2))
          )
          .inputStyle(color: .brand)
          .accentColor(.brand)
        }

        CustomSection(label: "Recurring Reminder") {
          VStack(spacing: 2) {

            HStack {
              Text("Set a reminder")
                .labelStyle(type: .secondary)

              Spacer()

              Toggle(
                "",
                isOn: Binding(
                  get: { recurringReminderEnabled },
                  set: { newValue in
                    withAnimation(.snappy) {
                      recurringReminderEnabled = newValue
                    }
                  }
                ))
            }
            .tint(Color.brand)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .sameLevelBorder()

            if recurringReminderEnabled {
              HStack {
                DatePicker(
                  "", selection: $reminderTime, displayedComponents: [.hourAndMinute]
                )
                .labelsHidden()
                .tint(Color.brand)
                .datePickerStyle(.wheel)
                .inputStyle(radius: 4, color: Color.brand)
              }
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.all, 2)
              .sameLevelBorder()
              .colorScheme(.dark)
            }
          }.padding(.all, 2)
            .background(getVoidColor(colorScheme: colorScheme))
        }

      }.padding()

    } lower: {
      VStack(alignment: .leading, spacing: 8) {
        Spacer()

        Text("Set your first habit.")
          .font(.system(size: 24, weight: .black, design: .monospaced))
          .foregroundStyle(.textPrimary)

        // To make habits stick, keep them:
        VStack(alignment: .leading) {
          Text("Step 1: Choose your focus (reading, learning, fitness, mindfulness)")
          Text("Step 2: Set a tiny daily action")
          Text("Step 3: Start today")
        }
        .multilineTextAlignment(.leading)
        .font(.system(size: 14, design: .monospaced))
        .foregroundStyle(.secondary)
      }
    }
  }
}
