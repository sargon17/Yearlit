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
  @State private var existingStreakEntries: [String: CalendarEntry] = [:]
  @State private var notificationPrivacyMode: NotificationPrivacyMode = .full
  @State private var suppressWhenCompleted: Bool = true

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

  private var trackingTypeLabel: String {
    switch trackingType {
    case .binary:
      return String(localized: "Binary")
    case .counter:
      return String(localized: "Counter")
    case .multipleDaily:
      return String(localized: "Target")
    }
  }

  private var trackingTypeDescription: LocalizedStringKey {
    switch trackingType {
    case .binary:
      return "Track a simple yes/no each day. Great for habits you either complete or skip."
    case .counter:
      return "Log a numeric value per day, like pages read or minutes practiced."
    case .multipleDaily:
      return "Check in multiple times per day toward a daily target."
    }
  }

  func userCanCreateCalendar() -> Bool {
    return customerInfo?.entitlements["premium"]?.isActive ?? false || store.calendars.count < 3
  }

  func createCalendar() {
    let calendar = CustomCalendar(
      name: name,
      color: selectedColor,
      trackingType: trackingType,
      dailyTarget: dailyTarget,
      entries: existingStreakEntries,
      isArchived: false,
      recurringReminderEnabled: recurringReminderEnabled,
      reminderTime: recurringReminderEnabled ? reminderTime : nil,
      unit: (trackingType == .counter || trackingType == .multipleDaily) ? selectedUnit : nil,
      defaultRecordValue: (trackingType == .counter || trackingType == .multipleDaily)
        ? defaultRecordValue : nil,
      currencySymbol: ((trackingType == .counter || trackingType == .multipleDaily)
        && selectedUnit == .currency) ? currencySymbol : nil,
      reminderTimeZone: TimeZone.current.identifier,
      notificationPrivacyMode: notificationPrivacyMode,
      suppressWhenCompleted: suppressWhenCompleted
    )
    scheduleNotifications(for: calendar)
    onCreate(calendar)
  }

  func handleCreateCalendar() {
    if !userCanCreateCalendar() {
      router.showScreen(.sheet) { _ in
        PaywallView(displayCloseButton: true)
      }
    } else {
      createCalendar()
    }
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        CustomSeparator()
          .padding(.horizontal, -16)
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

        ZStack(alignment: .leading) {
          Text(trackingTypeDescription)
            .font(.footnote)
            .foregroundStyle(.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
            .id(trackingType)
            .transition(.blurReplace)
        }
        .animation(.snappy, value: trackingType)

        if trackingType == .multipleDaily || trackingType == .counter {
          CustomSection(label: "Settings for \(trackingTypeLabel)") {

            VStack(spacing: 2) {

              if trackingType == .multipleDaily {
                HStack {
                  Text("Daily Target")
                    .labelStyle(type: .secondary)

                  Spacer()
                  TextField("Target", value: $dailyTarget, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
                    .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                }
                .padding(.leading)
                .padding(.all, 2)
                .sameLevelBorder(isFlat: true)
              }

              if trackingType == .counter || trackingType == .multipleDaily {
                HStack {
                  Text("Unit of Measure")
                    .labelStyle(type: .secondary)

                  Spacer()
                  if selectedUnit == nil {
                    Text("None")
                  }
                  Picker("Unit of Measure", selection: $selectedUnit) {
                    ForEach(UnitOfMeasure.Category.allCases, id: \.self) {
                      category in
                      Section(header: Text(category.displayName)) {
                        ForEach(UnitOfMeasure.allCasesGrouped[category] ?? [], id: \.self) { unit in
                          Text(unit.displayName).tag(unit as UnitOfMeasure?)
                        }
                      }
                    }
                  }
                }
                .padding(.leading)
                .padding(.vertical, 8)
                .sameLevelBorder(isFlat: true)

                if selectedUnit == .currency {
                  HStack {
                    Text("Currency Symbol")
                      .labelStyle(type: .secondary)

                    Spacer()
                    TextField("Symbol", text: $currencySymbol)
                      .multilineTextAlignment(.trailing)
                      .frame(maxWidth: 100)
                      .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                  }
                  .padding(.leading)
                  .padding(.all, 2)
                  .sameLevelBorder(isFlat: true)

                }

              }

              if trackingType == .counter || trackingType == .multipleDaily {
                HStack {
                  Text("Default Quick Add Value")
                    .labelStyle(type: .secondary)

                  Spacer()
                  TextField("Value", value: $defaultRecordValue, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
                    .inputStyle(size: .large, radius: 4, color: Color(selectedColor))
                }
                .padding(.leading)
                .padding(.all, 2)
                .sameLevelBorder(isFlat: true)

              }
            }
            .padding(.all, 2)
            .background(getVoidColor(colorScheme: colorScheme))

          }
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
            .tint(Color(selectedColor))
            .padding(.horizontal)
            .padding(.vertical, 6)
            .sameLevelBorder(isFlat: true)

            if recurringReminderEnabled {
              HStack {
                DatePicker(
                  "", selection: $reminderTime, displayedComponents: [.hourAndMinute]
                )
                .labelsHidden()
                .tint(Color(selectedColor))
                .datePickerStyle(.wheel)
                .inputStyle(radius: 4, color: Color(selectedColor))
              }
              .frame(maxWidth: .infinity, alignment: .center)
              .padding(.all, 2)
              .sameLevelBorder(isFlat: true)
              .colorScheme(.dark)
              
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("Privacy Level")
                    .labelStyle(type: .secondary)
                  Text(notificationPrivacyMode.detail)
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                }
                Spacer()
                Picker("Privacy Level", selection: $notificationPrivacyMode) {
                  ForEach(NotificationPrivacyMode.allCases, id: \.self) { mode in
                    Text(mode.description).tag(mode)
                  }
                }
                .pickerStyle(.menu)
                .tint(Color(selectedColor))
              }
              .padding(.horizontal)
              .padding(.vertical, 8)
              .sameLevelBorder(isFlat: true)
              
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("Smart Suppression")
                    .labelStyle(type: .secondary)
                  Text("Don't notify if already completed")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                }
                Spacer()
                Toggle("", isOn: $suppressWhenCompleted)
              }
              .tint(Color(selectedColor))
              .padding(.horizontal)
              .padding(.vertical, 8)
              .sameLevelBorder(isFlat: true)
            }
          }.padding(.all, 2)
            .background(getVoidColor(colorScheme: colorScheme))
        }
        CustomSection(label: "Already active streak?") {
          VStack(spacing: 8) {
            if !existingStreakEntries.isEmpty {
              Text("Backfilling \(existingStreakEntries.count) days.")
                .font(.footnote)
                .foregroundStyle(.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
            }

            Button(action: {
              router.showScreen(.sheet) { _ in
                ExistingStreakSheet(
                  trackingType: trackingType,
                  dailyTarget: dailyTarget,
                  defaultDailyValue: defaultRecordValue,
                  existingEntries: [:],
                  accentColor: Color(selectedColor)
                ) { entries in
                  existingStreakEntries = entries
                }
              }
            }) {
              Text("Add existing streak")
                .frame(maxWidth: .infinity, alignment: .center)
                .fontWeight(.bold)
                .padding()
            }
            .sameLevelBorder()
            .foregroundStyle(.textSecondary)
          }
          .padding(.all, 2)
          .background(getVoidColor(colorScheme: colorScheme))
        }
        Text("Already started elsewhere? Bring your streak here.")
          .font(.footnote)
          .foregroundStyle(.textTertiary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 8)

        CustomSection(label: "Color") {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              ForEach(colors, id: \.self) { color in
                Circle()
                  .fill(Color(color))
                  .frame(width: 30, height: 30)
                  .overlay(
                    Circle()
                      .stroke(.white, lineWidth: selectedColor == color ? 2 : 0)
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
          .patternStyle()
          .cornerRadius(6)

        }

        CustomSeparator()
          .padding(.horizontal, -16)
      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    }
    .accentColor(Color(selectedColor))
    .scrollClipDisabled(true)
    .scrollDismissesKeyboard(.immediately)
    .scrollContentBackground(.hidden)
    .scrollIndicators(.hidden)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
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
          if !userCanCreateCalendar() {
            router.showScreen(.sheet) { _ in
              PaywallView(displayCloseButton: false)
            }
          } else {
            createCalendar()
            router.dismissScreen()
          }
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
    .onChange(of: trackingType) { _, _ in
      existingStreakEntries = [:]
    }
    .onChange(of: dailyTarget) { _, _ in
      if trackingType == .multipleDaily {
        existingStreakEntries = [:]
      }
    }
  }

}
