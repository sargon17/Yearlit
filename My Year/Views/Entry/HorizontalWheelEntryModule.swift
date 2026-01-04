import SharedModels
import SwiftUI

struct HorizontalWheelEntryModule: View {
  let calendar: CustomCalendar
  @Binding var entryCount: Int

  @State private var maxValue: Int
  @FocusState private var isCountFocused: Bool

  init(calendar: CustomCalendar, entryCount: Binding<Int>) {
    self.calendar = calendar
    _entryCount = entryCount
    let baseMax = max(entryCount.wrappedValue + 200, 200)
    let boostedMax = max(baseMax, calendar.dailyTarget * 5)
    _maxValue = State(initialValue: boostedMax)
  }

  var body: some View {
    VStack(spacing: 24) {
      CustomSection(label: "Count") {
        VStack(spacing: 12) {
          TextField("", value: $entryCount, formatter: countFormatter)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .greatestFiniteMagnitude)
            .inputStyle(color: Color(calendar.color))
            .keyboardType(.numberPad)
            .focused($isCountFocused)

          HorizontalTickWheel(
            value: $entryCount,
            maxValue: $maxValue,
            accentColor: Color(calendar.color)
          )
        }
        .padding(2)
        .outerSameLevelShadow()
      }
    }
  }
}

private var countFormatter: NumberFormatter {
  let formatter = NumberFormatter()
  formatter.numberStyle = .none
  return formatter
}

private struct HorizontalTickWheel: View {
  @Binding var value: Int
  @Binding var maxValue: Int
  let accentColor: Color
  @State private var lastHapticValue: Int? = nil
  @State private var selection: Int? = nil

  private let tickSpacing: CGFloat = 10
  private let tickWidth: CGFloat = 2
  private let majorTickHeight: CGFloat = 18
  private let minorTickHeight: CGFloat = 10

  var body: some View {
    GeometryReader { geometry in
      let sidePadding = max(0, (geometry.size.width - tickWidth) / 2)

      ScrollView(.horizontal) {
        LazyHStack(spacing: tickSpacing) {
          ForEach(0...maxValue, id: \.self) { index in
            let isMajor = index % 5 == 0
            RoundedRectangle(cornerRadius: 1)
              .fill(isMajor ? Color.textSecondary : Color.textTertiary)
              .frame(width: tickWidth, height: isMajor ? majorTickHeight : minorTickHeight)
              .id(index)
          }
        }
        .scrollTargetLayout()
        .padding(.horizontal, sidePadding)
      }
      .scrollIndicators(.hidden)
      .scrollPosition(id: $selection, anchor: .center)
      .onChange(of: selection) { _, newValue in
        guard let newValue else { return }
        if value != newValue {
          value = newValue
        }
        if newValue != lastHapticValue {
          lastHapticValue = newValue
          Task {
            await hapticFeedback(.light)
          }
        }
        if newValue >= maxValue - 20 {
          maxValue += 200
        }
      }
      .onChange(of: value) { _, newValue in
        if selection != newValue {
          selection = newValue
        }
      }
      .onAppear {
        selection = value
        lastHapticValue = value
      }
      .overlay(alignment: .center) {
        RoundedRectangle(cornerRadius: 1)
          .fill(accentColor)
          .frame(width: 2, height: 24)
      }
    }
    .frame(height: 44)
  }
}
