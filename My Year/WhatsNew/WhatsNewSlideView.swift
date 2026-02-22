import SwiftUI

struct WhatsNewSlideView: View {
    let slide: WhatsNewSlide

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                headerView
                    .frame(width: proxy.size.width)
                    .frame(maxHeight: .infinity)
                    .clipped()

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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(width: proxy.size.width, alignment: .leading)
                .background(.surfaceMuted)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .background(.surfaceMuted)
        }
    }

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
