import RevenueCat
import RevenueCatUI
import SharedModels
import SwiftUI

struct CreateCalendarView: View {
  @Environment(\.dismiss) private var dismiss
  let onCreate: (CustomCalendar) -> Void

  @State private var customerInfo: CustomerInfo?
  @ObservedObject private var store = CustomCalendarStore.shared
  @State private var name = ""
  @State private var selectedColor = "mood-good"
  @State private var trackingType: TrackingType = .binary
  @State private var dailyTarget = 2
  @State private var recurringReminderEnabled: Bool = false
  @State private var reminderTime: Date = Date()
  @State private var selectedUnit: UnitOfMeasure? = nil
  @State private var defaultRecordValue: Int = 1
  @State private var isPaywallPresented = false
  @State private var errorMessage: String?
  @State private var isAlertPresented = false
  @State private var currencySymbol: String = "$"

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
    "qs-rose",
  ]

  func userCanCreateCalendar() -> Bool {
    return customerInfo?.entitlements["premium"]?.isActive ?? false || store.calendars.count < 3
  }

  func createCalendar() {
    do {
      let calendar = CustomCalendar(
        name: name,
        color: selectedColor,
        trackingType: trackingType,
        dailyTarget: dailyTarget,
        recurringReminderEnabled: recurringReminderEnabled,
        reminderTime: recurringReminderEnabled ? reminderTime : nil,
        unit: (trackingType == .counter || trackingType == .multipleDaily) ? selectedUnit : nil,
        defaultRecordValue: (trackingType == .counter || trackingType == .multipleDaily) ? defaultRecordValue : nil,
        currencySymbol: ((trackingType == .counter || trackingType == .multipleDaily) && selectedUnit == .currency) ? currencySymbol : nil
      )
      onCreate(calendar)
    } catch {
      errorMessage = "Error creating calendar, please try again."
    }
  }

  func handleCreateCalendar() {
    if !userCanCreateCalendar() {
      isPaywallPresented = true
    } else {
      createCalendar()
    }
  }


  var body: some View {
    Form {
      Section {
        TextField("Calendar Name", text: $name)
          .foregroundColor(Color("text-primary"))
          .fontWeight(.bold)
      }
      .listRowBackground(Color("surface-secondary"))

      Section {
        Picker("Tracking Type", selection: $trackingType) {
          Text("Once a day").tag(TrackingType.binary)
          Text("Multiple times (unlimited)").tag(TrackingType.counter)
          Text("Multiple times (with target)").tag(TrackingType.multipleDaily)
        }

        if trackingType == .multipleDaily {
          HStack {
            Text("Daily Target")
            Spacer()
            TextField("Target", value: $dailyTarget, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
          }
        }

        if trackingType == .counter || trackingType == .multipleDaily {
          Section {
            Picker("Unit of Measure", selection: $selectedUnit) {
              Text("None").tag(nil as UnitOfMeasure?)
              ForEach(UnitOfMeasure.Category.allCases, id: \.self) { category in
                Section(header: Text(category.rawValue)) {
                  ForEach(UnitOfMeasure.allCasesGrouped[category] ?? [], id: \.self) { unit in
                    Text(unit.displayName).tag(unit as UnitOfMeasure?)
                  }
                }
              }
            }

            if selectedUnit == .currency {
              HStack {
                Text("Currency Symbol")
                Spacer()
                TextField("Symbol", text: $currencySymbol)
                  .multilineTextAlignment(.trailing)
                  .frame(maxWidth: 100)
              }
            }
          }
          .listRowBackground(Color("surface-secondary"))
        }

        if trackingType == .counter || trackingType == .multipleDaily {
            Section {
                HStack {
                    Text("Default Quick Add Value")
                    Spacer()
                    TextField("Value", value: $defaultRecordValue, formatter: NumberFormatter()) 
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                }
            }
            .listRowBackground(Color("surface-secondary"))
        }
      }
      .listRowBackground(Color("surface-secondary"))

      Section {
        Toggle("Recurring Reminder", isOn: $recurringReminderEnabled)
        if recurringReminderEnabled {
          DatePicker(
            "Reminder Time", selection: $reminderTime, displayedComponents: [.hourAndMinute])
        }
      }
      .listRowBackground(Color("surface-secondary"))

      Section {
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
                selectedColor = color
                }
              }
            }.padding(2)
            .padding(.horizontal, 10)
          }.padding(.horizontal, -20)
        } header: {
          Text("Color")
        }
      .listRowBackground(Color("surface-secondary"))
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
          handleCreateCalendar()
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
        Purchases.shared.getCustomerInfo { (info, error) in
            if let e = error {
                print("Error fetching customer info: \(e.localizedDescription)")
                return
            }
            self.customerInfo = info
        }
    }
  }
}
