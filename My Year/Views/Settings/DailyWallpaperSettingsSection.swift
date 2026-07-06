import RevenueCat
import SwiftUI
import SwiftfulRouting
import UIKit

struct DailyWallpaperSettingsSection: View {
  @Environment(\.router) private var router
  let customerInfo: CustomerInfo?

  var body: some View {
    Section(header: Text("Daily Wallpaper")) {
      Button {
        router.showScreen(.sheet) { _ in
          NavigationStack {
            DailyWallpaperSetupView(customerInfo: customerInfo)
          }
          .presentationDetents([.large])
          .presentationDragIndicator(.visible)
        }
      } label: {
        Label("Set Up Daily Wallpaper", systemImage: "photo.on.rectangle")
      }
    }
  }
}

private struct DailyWallpaperSetupView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.router) private var router

  let customerInfo: CustomerInfo?
  @State private var selectedTemplate: DailyWallpaperTemplate
  @State private var visibleTemplate: DailyWallpaperTemplate
  @State private var selectedTheme: DailyWallpaperTheme
  @State private var selectedAccentColor: String
  @State private var messageText: String
  @State private var isInstallationGuidePresented = false

  private var isPremiumUser: Bool {
    isPremium(customerInfo: customerInfo)
      || (customerInfo == nil && DailyWallpaperSettingsStore.hasCachedPremiumAccess())
  }

  private var selectedTemplateSupportsMessage: Bool {
    selectedTemplate.supportsMessage && isPremiumUser
  }

  private var effectiveAccentColorName: String {
    isPremiumUser ? selectedAccentColor : DailyWallpaperSettingsStore.defaultAccentColorName
  }

  private var effectiveAccentColor: Color {
    Color(effectiveAccentColorName)
  }

  init(customerInfo: CustomerInfo?) {
    let settings = DailyWallpaperSettingsStore.savedSettings()
    self.customerInfo = customerInfo
    _selectedTemplate = State(initialValue: settings.template)
    _visibleTemplate = State(initialValue: settings.template)
    _selectedTheme = State(initialValue: settings.theme)
    _selectedAccentColor = State(initialValue: settings.accentColorName)
    _messageText = State(initialValue: settings.message ?? "")
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 26) {
        DailyWallpaperTemplatePager(
          visibleTemplate: $visibleTemplate,
          selectedTemplate: selectedTemplate,
          isPremiumUser: isPremiumUser,
          accentColor: effectiveAccentColor,
          settings: previewSettings(for:),
          onSelect: selectTemplate
        )
        DailyWallpaperSettingsGroup("Theme") {
          WallpaperThemePicker(
            selectedTheme: selectedTheme,
            accentColor: effectiveAccentColor
          ) { theme in
            selectedTheme = theme
            DailyWallpaperSettingsStore.saveTheme(theme)
          }
        }
        DailyWallpaperSettingsGroup(
          "Accent Color",
          footer: "Changes the current-day dot and highlighted progress number."
        ) {
          if isPremiumUser {
            ColorSwatchPicker(
              selectedColor: $selectedAccentColor,
              accessibilityHint: "Select wallpaper accent color"
            )
          } else {
            Button {
              showPremiumPaywall()
            } label: {
              LockedWallpaperOptionRow(
                title: "Custom accent color",
                showsLock: true
              )
            }
            .buttonStyle(.plain)
          }
        }
        DailyWallpaperSettingsGroup(
          "Message"
        ) {
          if selectedTemplateSupportsMessage {
            TextField(
              "",
              text: messageBinding,
              prompt: Text("One honest day at a time").foregroundColor(.white.opacity(0.2))
            )
            .inputStyle(color: effectiveAccentColor)
            .textInputAutocapitalization(.sentences)
          } else {
            Button {
              if !isPremiumUser {
                showPremiumPaywall()
              }
            } label: {
              LockedWallpaperOptionRow(
                title: "Custom message",
                showsLock: !isPremiumUser
              )
            }
            .buttonStyle(.plain)
            .disabled(isPremiumUser)
          }
        }
        DailyWallpaperSettingsGroup(
          "Installation",
          footer: "Your real wallpaper changes only when the Shortcut runs, on schedule or manually."
        ) {
          Button {
            isInstallationGuidePresented = true
          } label: {
            LockedWallpaperOptionRow(
              title: "How to set this up",
              subtitle: "Create the Shortcut that applies the wallpaper.",
              showsLock: false,
              accentColor: effectiveAccentColor,
              trailingIconName: "chevron.right"
            )
          }
          .buttonStyle(.plain)
          .accessibilityLabel(Text("How to set this up"))
          .accessibilityHint(Text("Opens setup instructions for Daily Wallpaper"))
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
    }
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .tint(effectiveAccentColor)
    .navigationTitle("Daily Wallpaper")
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Done") {
          dismiss()
        }
      }
    }
    .onChange(of: selectedAccentColor) { _, colorName in
      DailyWallpaperSettingsStore.saveAccentColorName(colorName)
    }
    .sheet(isPresented: $isInstallationGuidePresented) {
      NavigationStack {
        DailyWallpaperInstallationGuideView(accentColor: effectiveAccentColor)
      }
      .presentationDetents([.large])
      .presentationDragIndicator(.visible)
    }
  }

  private func previewSettings(for template: DailyWallpaperTemplate) -> DailyWallpaperSettings {
    return DailyWallpaperSettings(
      template: template,
      theme: selectedTheme,
      accentColorName: effectiveAccentColorName,
      message: isPremiumUser && template.supportsMessage ? messageText : nil
    )
  }

  private var messageBinding: Binding<String> {
    Binding(
      get: { messageText },
      set: { newValue in
        messageText = DailyWallpaperSettingsStore.sanitizedMessage(newValue) ?? ""
        DailyWallpaperSettingsStore.saveMessage(messageText)
      }
    )
  }

  private func selectTemplate(_ template: DailyWallpaperTemplate) {
    guard isPremiumUser || !template.isPremium else {
      showPremiumPaywall()
      return
    }

    selectedTemplate = template
    visibleTemplate = template
    DailyWallpaperSettingsStore.saveTemplate(template)
  }

  private func showPremiumPaywall() {
    router.showScreen(.sheet) { _ in
      OnboardingPaywall(
        showsCloseButton: true,
        isPresentedAsSheet: true,
        trigger: .settingsSupport,
        onNext: {}
      )
    }
  }
}

private struct DailyWallpaperSettingsGroup<Content: View>: View {
  let title: LocalizedStringKey
  let footer: LocalizedStringKey?
  let content: () -> Content

  init(
    _ title: LocalizedStringKey,
    footer: LocalizedStringKey? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.footer = footer
    self.content = content
  }

  var body: some View {
    CustomSection(label: title) {
      content()

      if let footer {
        Text(footer)
          .font(.footnote)
          .foregroundStyle(.textTertiary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 8)
          .padding(.top, 8)
      }
    }
  }
}

private struct WallpaperThemePicker: View {
  let selectedTheme: DailyWallpaperTheme
  let accentColor: Color
  let onSelect: (DailyWallpaperTheme) -> Void

  var body: some View {
    HStack(spacing: 2) {
      ForEach(DailyWallpaperTheme.allCases) { theme in
        themeButton(for: theme)
      }
    }
    .padding(.all, 2)
    .frame(maxWidth: .greatestFiniteMagnitude)
    .sameLevelGroupBackground()
  }

  private func themeButton(for theme: DailyWallpaperTheme) -> some View {
    Button {
      withAnimation(.snappy) { onSelect(theme) }
      Task { await hapticFeedback(.rigid) }
    } label: {
      PickerOptionTile(isSelected: selectedTheme == theme, isEnabled: true) {
        PickerOptionContent(
          icon: theme.systemImageName,
          title: theme.displayName,
          accentColor: accentColor,
          isSelected: selectedTheme == theme
        )
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(theme.displayName))
  }
}

private struct DailyWallpaperTemplatePager: View {
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

private struct LockedWallpaperOptionRow: View {
  let title: LocalizedStringKey
  var subtitle: LocalizedStringKey?
  var iconName: String?
  let showsLock: Bool
  var accentColor: Color?
  var trailingIconName: String?

  var body: some View {
    HStack(spacing: 12) {
      if let iconName {
        Image(systemName: iconName)
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(accentColor ?? Color("text-secondary"))
          .frame(width: 22)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(AppFont.mono(12, weight: subtitle == nil ? .regular : .bold))
          .foregroundColor(Color("text-primary"))
        if let subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.textTertiary)
        }
      }

      Spacer()

      if showsLock {
        Image(systemName: "lock.fill")
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(Color("text-tertiary"))
      }
      if let trailingIconName {
        Image(systemName: trailingIconName)
          .font(AppFont.mono(12))
          .foregroundColor(accentColor ?? Color("text-tertiary"))
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 10)
    .sameLevelBorder(isFlat: true)
    .accessibilityElement(children: .combine)
  }
}

private struct DailyWallpaperPreview: View {
  let settings: DailyWallpaperSettings

  var body: some View {
    ZStack {
      Color("surface-muted")

      if let image = DailyWallpaperRenderer.renderPreview(settings: settings) {
        Image(uiImage: image)
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
  }
}

extension DailyWallpaperTheme {
  fileprivate var displayName: LocalizedStringKey {
    switch self {
    case .dark: "Dark"
    case .light: "Light"
    }
  }

  fileprivate var systemImageName: String {
    switch self {
    case .dark: "moon.fill"
    case .light: "sun.max.fill"
    }
  }
}

#Preview {
  NavigationStack {
    DailyWallpaperSetupView(customerInfo: nil)
  }
}
