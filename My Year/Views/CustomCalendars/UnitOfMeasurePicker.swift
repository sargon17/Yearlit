import SharedModels
import SwiftUI

struct UnitOfMeasurePicker: View {
  @Binding var selection: UnitOfMeasure?

  var body: some View {
    Picker("Unit of Measure", selection: $selection) {
      ForEach(UnitOfMeasure.Category.allCases, id: \.self) { category in
        Section(header: Text(category.displayName)) {
          ForEach(UnitOfMeasure.allCasesGrouped[category] ?? [], id: \.self) { unit in
            Text(unit.displayName).tag(unit as UnitOfMeasure?)
          }
        }
      }
    }
  }
}
