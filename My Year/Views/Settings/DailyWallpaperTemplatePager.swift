import SwiftUI

struct DailyWallpaperTemplatePager: View {
  @Binding var visibleTemplate: DailyWallpaperTemplate
  let selectedTemplate: DailyWallpaperTemplate
  let isPremiumUser: Bool
  let accentColor: Color
  let settings: (DailyWallpaperTemplate) -> DailyWallpaperSettings
  let onSelect: (DailyWallpaperTemplate) -> Void

  var body: some View {
    GeometryReader { proxy in
      let cardWidth = min(proxy.size.width * 0.68, 238)
      let sideInset = max((proxy.size.width - cardWidth) / 2, 18)

      ScrollViewReader { reader in
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(spacing: 18) {
            ForEach(DailyWallpaperTemplate.allCases) { template in
              DailyWallpaperTemplatePage(
                template: template,
                isSelected: selectedTemplate == template,
                isLocked: template.isPremium && !isPremiumUser,
                accentColor: accentColor,
                settings: settings(template),
                onSelect: onSelect
              )
              .frame(width: cardWidth)
              .id(template)
            }
          }
          .scrollTargetLayout()
          .padding(.vertical, 6)
        }
        .scrollClipDisabled()
        .contentMargins(.horizontal, sideInset, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .onAppear {
          reader.scrollTo(visibleTemplate, anchor: .center)
        }
        .onChange(of: visibleTemplate) { _, template in
          withAnimation(.snappy(duration: 0.28)) {
            reader.scrollTo(template, anchor: .center)
          }
        }
      }
    }
    .frame(height: 500)
    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 10, trailing: 0))
  }
}

private struct DailyWallpaperTemplatePage: View {
  let template: DailyWallpaperTemplate
  let isSelected: Bool
  let isLocked: Bool
  let accentColor: Color
  let settings: DailyWallpaperSettings
  let onSelect: (DailyWallpaperTemplate) -> Void

  var body: some View {
    VStack(spacing: 12) {
      DailyWallpaperPreview(settings: settings)

      HStack(spacing: 10) {
        Text(template.displayName)
          .font(AppFont.mono(12, weight: isSelected ? .bold : .regular))
          .foregroundColor(Color("text-primary"))
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        Spacer()

        WallpaperSelectionButton(
          template: template,
          isSelected: isSelected,
          isLocked: isLocked,
          accentColor: accentColor,
          onSelect: onSelect
        )
      }
      .padding(.horizontal, 12)
    }
  }
}

private struct WallpaperSelectionButton: View {
  let template: DailyWallpaperTemplate
  let isSelected: Bool
  let isLocked: Bool
  let accentColor: Color
  let onSelect: (DailyWallpaperTemplate) -> Void

  var body: some View {
    Button {
      onSelect(template)
    } label: {
      Image(systemName: isLocked ? "lock.fill" : "checkmark")
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(isSelected ? .surfaceMuted : accentColor)
        .frame(width: 20, height: 20)
        .background(isSelected ? accentColor : accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(template.displayName))
    .accessibilityHint(Text(isLocked ? "Unlock premium wallpaper" : "Select wallpaper"))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
