import SwiftUI
import UIKit

struct DailyWallpaperPreview: View {
  let settings: DailyWallpaperSettings
  @State private var previewImage: UIImage?
  @State private var renderedSettings: DailyWallpaperSettings?

  var body: some View {
    ZStack {
      Color("surface-muted")

      if let previewImage {
        Image(uiImage: previewImage)
          .resizable()
          .scaledToFill()
          .overlay {
            RoundedRectangle(cornerRadius: 18)
              .stroke(.deviderTop, lineWidth: 4)
          }
          .overlay {
            RoundedRectangle(cornerRadius: 18)
              .stroke(.deviderBottom, lineWidth: 2)
          }
      }
    }
    .aspectRatio(430 / 932, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .frame(maxWidth: .infinity)
    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 12)
    .onAppear(perform: renderIfNeeded)
    .onChange(of: settings) {
      renderIfNeeded()
    }
  }

  @MainActor
  private func renderIfNeeded() {
    guard renderedSettings != settings else { return }
    renderedSettings = settings
    previewImage = DailyWallpaperRenderer.renderPreview(settings: settings)
  }
}
