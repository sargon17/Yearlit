import SharedModels
import SwiftUI

struct CalendarValueSettingsSection: View {
  let label: LocalizedStringKey
  let targetLabel: String
  let showsTarget: Bool
  let showsUnitSettings: Bool
  let color: Color
  @Binding var dailyTarget: Int
  @Binding var selectedUnit: UnitOfMeasure?
  @Binding var currencySymbol: String
  @Binding var defaultRecordValue: Int

  var body: some View {
    CustomSection(label: label) {
      VStack(spacing: 2) {
        if showsTarget {
          targetRow
        }

        if showsUnitSettings {
          unitRow

          if selectedUnit == .currency {
            currencyRow
          }

          quickAddRow
        }
      }
      .padding(.all, 2)
      .sameLevelGroupBackground()
    }
  }

  private var targetRow: some View {
    HStack {
      Text(targetLabel)
        .labelStyle(type: .secondary)

      Spacer()
      TextField("Target", value: $dailyTarget, formatter: NumberFormatter())
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: 100)
        .inputStyle(size: .large, radius: 4, color: color)
    }
    .padding(.leading)
    .padding(.all, 2)
    .sameLevelBorder(isFlat: true)
  }

  private var unitRow: some View {
    HStack {
      Text("Unit of Measure")
        .labelStyle(type: .secondary)

      Spacer()
      UnitOfMeasurePicker(selection: $selectedUnit)
    }
    .padding(.leading)
    .padding(.vertical, 8)
    .sameLevelBorder(isFlat: true)
  }

  private var currencyRow: some View {
    HStack {
      Text("Currency Symbol")
        .labelStyle(type: .secondary)

      Spacer()
      TextField("Symbol", text: $currencySymbol)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: 100)
        .inputStyle(size: .large, radius: 4, color: color)
    }
    .padding(.leading)
    .padding(.all, 2)
    .sameLevelBorder(isFlat: true)
  }

  private var quickAddRow: some View {
    HStack {
      Text("Default Quick Add Value")
        .labelStyle(type: .secondary)

      Spacer()
      TextField("Value", value: $defaultRecordValue, formatter: NumberFormatter())
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: 100)
        .inputStyle(size: .large, radius: 4, color: color)
    }
    .padding(.leading)
    .padding(.all, 2)
    .sameLevelBorder(isFlat: true)
  }
}
