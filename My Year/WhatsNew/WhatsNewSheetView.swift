import SwiftUI

struct WhatsNewSheetView: View {
  let release: WhatsNewRelease
  let onDone: () -> Void

  @State private var currentIndex: Int = 0

  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    VStack(spacing: 0) {
      TabView(selection: $currentIndex) {
        ForEach(Array(release.slides.enumerated()), id: \.element.id) { index, slide in
          WhatsNewSlideView(slide: slide)
            .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .scrollIndicators(.hidden)

      footer
    }
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
  }

  private var footer: some View {
    VStack(spacing: 12) {
      HStack(spacing: 6) {
        ForEach(0..<release.slides.count, id: \.self) { index in
          Circle()
            .fill(index == currentIndex ? Color("text-primary") : Color("text-tertiary"))
            .frame(width: 6, height: 6)
            .animation(.easeInOut, value: currentIndex)
        }
      }


      VStack {
      VStack {
      Button(action: handleNext) {
        Text(isLastSlide ? "Done" : "Next")
          .frame(maxWidth: .infinity)
          .padding()
          .foregroundColor(.brandInverted)
          .font(.system(size: 16, weight: .bold, design: .monospaced))
          .clipShape(RoundedRectangle(cornerRadius: 6))
      }
      .sameLevelBorder(color: .brand)
      }.padding(.all, 2)
      .background(getVoidColor(colorScheme: colorScheme))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
    }
  }

  private var isLastSlide: Bool {
    currentIndex >= release.slides.count - 1
  }

  private func handleNext() {
    if isLastSlide {
      onDone()
      dismiss()
    } else {
      withAnimation {
        currentIndex += 1
      }
    }
  }
}
