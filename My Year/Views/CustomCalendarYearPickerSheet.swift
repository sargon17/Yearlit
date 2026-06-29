import SwiftUI

struct CustomCalendarYearPickerSheet: View {
  @Binding var isPresented: Bool
  @Binding var selectedYear: Int
  @Binding var tempSelectedYear: Int
  let availableYears: [Int]

  var body: some View {
    NavigationStack {
      VStack {
        Picker("Select Year", selection: $tempSelectedYear) {
          ForEach(availableYears, id: \.self) { year in
            Text(year.description)
              .foregroundColor(Color("text-primary"))
              .tag(year)
          }
        }
        .pickerStyle(.wheel)
      }
      .navigationTitle("Select Year")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: cancel)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Done", action: save)
        }
      }
      .onAppear {
        tempSelectedYear = selectedYear
      }
    }
    .presentationDetents([.height(280)])
  }

  private func cancel() {
    tempSelectedYear = selectedYear
    isPresented = false
  }

  private func save() {
    selectedYear = tempSelectedYear
    isPresented = false
  }
}
