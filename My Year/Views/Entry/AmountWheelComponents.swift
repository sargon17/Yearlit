import SwiftUI

struct VerticalAmountTickWheel: View {
  @Binding var value: Int
  @Binding var maxValue: Int
  let accentColor: Color

  @State private var lastHapticValue: Int?
  @State private var selection: Int?

  private let tickSpacing: CGFloat = 10
  private let tickHeight: CGFloat = 2
  private let majorTickWidth: CGFloat = 34
  private let minorTickWidth: CGFloat = 18

  var body: some View {
    GeometryReader { geometry in
      let verticalPadding = max(0, (geometry.size.height - tickHeight) / 2)

      ScrollView(.vertical) {
        LazyVStack(spacing: tickSpacing) {
          ForEach(0...maxValue, id: \.self) { index in
            tick(at: index)
          }
        }
        .scrollTargetLayout()
        .padding(.vertical, verticalPadding)
      }
      .scrollIndicators(.hidden)
      .scrollPosition(id: $selection, anchor: .center)
      .scrollTargetBehavior(.viewAligned)
      .mask { WheelFadeMask() }
      .overlay(alignment: .center) {
        RoundedRectangle(cornerRadius: 1)
          .fill(accentColor)
          .frame(height: 2)
          .padding(.horizontal, 14)
      }
      .onChange(of: selection) { _, newValue in
        updateSelection(newValue)
      }
      .onChange(of: value) { _, newValue in
        if selection != newValue {
          selection = newValue
        }
      }
      .onAppear {
        selection = nil
        lastHapticValue = value
        Task { @MainActor in
          selection = value
        }
      }
    }
  }

  private func tick(at index: Int) -> some View {
    let isMajor = index % 5 == 0
    return RoundedRectangle(cornerRadius: 1)
      .fill(isMajor ? Color.textSecondary : Color.textTertiary)
      .frame(width: isMajor ? majorTickWidth : minorTickWidth, height: tickHeight)
      .frame(maxWidth: .infinity)
      .id(index)
  }

  private func updateSelection(_ newValue: Int?) {
    guard let newValue else { return }
    if value != newValue {
      value = newValue
    }
    if newValue != lastHapticValue {
      lastHapticValue = newValue
      Task {
        await hapticFeedback(newValue % 5 == 0 ? .light : .soft)
      }
    }
    if newValue >= maxValue - 20 {
      maxValue += 200
    }
  }
}
