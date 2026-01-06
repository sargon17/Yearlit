import SwiftUI

struct WhatsNewSlideView: View {
  let slide: WhatsNewSlide

  var body: some View {
    GeometryReader { geometry in
      let height = geometry.size.height

      VStack(spacing: 0) {
        headerView
          .frame(height: height * 0.6)

        CustomSeparator()

        VStack(alignment: .leading, spacing: 12) {
          Text(slide.title)
            .font(.system(size: 20, weight: .bold, design: .monospaced))
            .foregroundColor(.textPrimary)

          if let subtitle = slide.subtitle {
            Text(subtitle)
              .body()
              .foregroundColor(.textSecondary)
          }

          contentView

          Spacer()
        }
        .frame(maxHeight: height * 0.4)
        .padding(.horizontal)
        .padding(.top, 12)
        .background(.surfaceMuted)
      }
      .background(.surfaceMuted)
    }
  }

  @ViewBuilder
  private var headerView: some View {
    ZStack {
      Color.clear

      if let imageName = slide.image {
        Image(imageName)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
      } else if let systemImage = slide.systemImage {
        Image(systemName: systemImage)
          .font(.system(size: 72, weight: .bold))
          .foregroundStyle(Color("text-tertiary"))
      } else {
        Image(systemName: "sparkles")
          .font(.system(size: 64, weight: .bold))
          .foregroundStyle(Color("text-tertiary"))
      }
    }
  }

  @ViewBuilder
  private var contentView: some View {
    switch slide.type {
    case .hero:
      if let body = slide.body {
        Text(body)
          .body()
          .foregroundColor(.textSecondary)
      }
    case .list:
      if let items = slide.items {
        VStack(alignment: .leading, spacing: 8) {
          ForEach(items, id: \.self) { item in
            HStack(alignment: .top, spacing: 8) {
              Text("•")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.textSecondary)
              Text(item)
                .body()
                .foregroundColor(.textSecondary)
            }
          }
        }
      }
    case .image, .text:
      if let body = slide.body {
        Text(body)
          .body()
          .foregroundColor(.textSecondary)
      }
    }
  }
}
