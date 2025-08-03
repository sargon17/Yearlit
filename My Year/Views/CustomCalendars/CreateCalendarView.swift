import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI
import SwiftfulRouting

struct CreateCalendarView: View {
  @Environment(\.dismiss) private var dismiss
  let onCreate: (CustomCalendar) -> Void

  @State private var customerInfo: CustomerInfo?
  @ObservedObject private var store = CustomCalendarStore.shared
  @State private var name = ""
  @State private var selectedColor = "qs-amber"
  @State private var trackingType: TrackingType = .binary
  @State private var dailyTarget = 2
  @State private var recurringReminderEnabled: Bool = false
  @State private var reminderTime: Date = Date()
  @State private var selectedUnit: UnitOfMeasure = .none
  @State private var defaultRecordValue: Int = 1
  @State private var isPaywallPresented = false
  @State private var errorMessage: String?
  @State private var isAlertPresented = false
  @State private var currencySymbol: String = "$"

  @FocusState private var isNameFocused: Bool
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.router) private var router

  private let colors = [
    "mood-terrible",
    "mood-bad",
    "qs-amber",
    "mood-neutral",
    "qs-lime",
    "mood-good",
    "qs-emerald",
    "qs-teal",
    "qs-cyan",
    "qs-sky",
    "qs-blue",
    "qs-indigo",
    "mood-excellent",
    "qs-fuchsia",
    "qs-pink",
    "qs-rose"
  ]

  func userCanCreateCalendar() -> Bool {
    return customerInfo?.entitlements["premium"]?.isActive ?? false || store.calendars.count < 3
  }

  func createCalendar() {
    let calendar = CustomCalendar(
      name: name,
      color: selectedColor,
      trackingType: trackingType,
      dailyTarget: dailyTarget,
      recurringReminderEnabled: recurringReminderEnabled,
      reminderTime: recurringReminderEnabled ? reminderTime : nil,
      unit: (trackingType == .counter || trackingType == .multipleDaily) ? selectedUnit : nil,
      defaultRecordValue: (trackingType == .counter || trackingType == .multipleDaily)
        ? defaultRecordValue : nil,
      currencySymbol: ((trackingType == .counter || trackingType == .multipleDaily)
        && selectedUnit == .currency) ? currencySymbol : nil
    )
    scheduleNotifications(for: calendar)
    onCreate(calendar)
  }

  func handleCreateCalendar() {
    if !userCanCreateCalendar() {
      isPaywallPresented = true
    } else {
      createCalendar()
    }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {

        CustomSection(label: "Calendar Name") {
          TextField(
            "",
            text: $name,
            prompt: Text("Daily Training").foregroundColor(.white.opacity(0.2))
          )
          .inputStyle(color: Color(selectedColor))
          .focused($isNameFocused)
        }

        TrackingPicker(trackingType: $trackingType, color: Color(selectedColor))

        if trackingType == .multipleDaily || trackingType == .counter {
          CustomSection(label: "Settings for \(trackingType.label)") {

            VStack(spacing: 2) {

              if trackingType == .multipleDaily {
                HStack {
                  Text("Daily Target")
                    .font(.system(size: 12, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.textTertiary)

                  Spacer()
                  TextField("Target", value: $dailyTarget, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
                    .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                }
                .padding(.leading)
                .padding(.all, 2)
                .sameLevelBorder()
              }

              if trackingType == .counter || trackingType == .multipleDaily {
                HStack {
                  Text("Unit of Measure")
                    .font(.system(size: 12, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.textTertiary)
                  Spacer()
                  if selectedUnit == nil {
                    Text("None")
                  }
                  Picker("Unit of Measure", selection: $selectedUnit) {
                    ForEach(UnitOfMeasure.Category.allCases, id: \.self) {
                      category in
                      Section(header: Text(category.rawValue)) {
                        ForEach(UnitOfMeasure.allCasesGrouped[category] ?? [], id: \.self) { unit in
                          Text(unit.displayName).tag(unit as UnitOfMeasure?)
                        }
                      }
                    }
                  }
                }
                .padding(.leading)
                .padding(.vertical, 8)
                .sameLevelBorder()

                if selectedUnit == .currency {
                  HStack {
                    Text("Currency Symbol")
                      .font(.system(size: 12, design: .monospaced).weight(.semibold))
                      .foregroundStyle(.textTertiary)
                    Spacer()
                    TextField("Symbol", text: $currencySymbol)
                      .multilineTextAlignment(.trailing)
                      .frame(maxWidth: 100)
                      .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                  }
                  .padding(.leading)
                  .padding(.all, 2)
                  .sameLevelBorder()

                }

              }

              if trackingType == .counter || trackingType == .multipleDaily {
                HStack {
                  Text("Default Quick Add Value")
                    .font(.system(size: 12, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.textTertiary)
                  Spacer()
                  TextField("Value", value: $defaultRecordValue, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
                    .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                }
                .padding(.leading)
                .padding(.all, 2)
                .sameLevelBorder()

              }
            }
            .padding(.all, 2)
            .background(getVoidColor(colorScheme: colorScheme))
            .cornerRadius(6)
            .outerSameLevelShadow(radius: 6)

          }
        }

        CustomSection(label: "Color") {
          ScrollView(.horizontal, showsIndicators: false) {
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
                    withAnimation(.snappy) {
                      selectedColor = color
                    }
                    Task {
                      await hapticFeedback(.rigid)
                    }
                  }
              }
            }.padding(2)
              .padding(.horizontal, 10)
          }
          .padding(.vertical)
          .scrollClipDisabled(true)
          .sameLevelBorder(radius: 6, color: .black)
          .outerSameLevelShadow(radius: 6)
          .patternStyle()
          .cornerRadius(6)

        }

        CustomSection(label: "Recurring Reminder") {
          VStack(spacing: 2) {

            HStack {
              Text("Set a remined")
                .font(.system(size: 12, design: .monospaced).weight(.semibold))
                .foregroundStyle(.textTertiary)
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
            .tint(Color(selectedColor))
            .padding(.horizontal)
            .padding(.vertical, 6)
            .sameLevelBorder()

            if recurringReminderEnabled {
              HStack {
                DatePicker(
                  "", selection: $reminderTime, displayedComponents: [.hourAndMinute]
                )
                .tint(Color(selectedColor))
                .datePickerStyle(.wheel)
                .inputStyle(radius: 4, color: Color(selectedColor))
              }
              .padding(.all, 2)
              .sameLevelBorder()
            }
          }.padding(.all, 2)
            .background(getVoidColor(colorScheme: colorScheme))
            .cornerRadius(6)
            .outerSameLevelShadow(radius: 6)
        }
      }
    }
    .accentColor(Color(selectedColor))
    .padding()
    .scrollClipDisabled(true)
    .scrollDismissesKeyboard(.immediately)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .background(Color.surfaceMuted)
    .navigationTitle("New Calendar")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          router.dismissScreen()
        }
      }
      ToolbarItem(placement: .confirmationAction) {
        Button("Create") {
          handleCreateCalendar()
          router.dismissScreen()
        }
        .disabled(name.isEmpty)
      }
    }
    .sheet(isPresented: $isPaywallPresented) {
      PaywallView(displayCloseButton: true)
    }
    .alert(isPresented: $isAlertPresented) {
      Alert(
        title: Text("Error"),
        message: Text(errorMessage ?? "An unknown error occurred"),
        dismissButton: .default(Text("OK")) {
          errorMessage = nil
          dismiss()
        }
      )
    }
    .onAppear {
      isNameFocused = true
      Purchases.shared.getCustomerInfo { (info, error) in
        // swiftlint:disable:next identifier_name
        if let e = error {
          print("Error fetching customer info: \(e.localizedDescription)")
          return
        }
        self.customerInfo = info
      }
    }
  }

}
