import RevenueCat
import RevenueCatUI
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
          settings: previewSettings(for:),
          onSelect: selectTemplate
        )

        DailyWallpaperSettingsGroup("Theme") {
          Picker(
            "Theme",
            selection: Binding(
              get: { selectedTheme },
              set: { theme in
                selectedTheme = theme
                DailyWallpaperSettingsStore.saveTheme(theme)
              }
            )
          ) {
            ForEach(DailyWallpaperTheme.allCases) { theme in
              Text(theme.displayName)
                .tag(theme)
            }
          }
          .pickerStyle(.segmented)
        }

        DailyWallpaperSettingsGroup(
          "Accent Color",
          footer: "The accent color changes the current-day dot and highlighted progress number."
        ) {
          if isPremiumUser {
            WallpaperAccentColorPicker(selectedColor: $selectedAccentColor)
          } else {
            Button {
              showPremiumPaywall()
            } label: {
              LockedWallpaperOptionRow(
                title: "Custom accent color",
                iconName: "paintpalette.fill",
                showsLock: true
              )
            }
            .buttonStyle(.plain)
          }
        }

        DailyWallpaperSettingsGroup(
          "Message",
          footer: "Premium message templates render up to two centered lines, 40 characters total."
        ) {
          if selectedTemplateSupportsMessage {
            TextField("One honest day at a time", text: messageBinding)
              .font(AppFont.mono(12))
              .textInputAutocapitalization(.sentences)
          } else {
            Button {
              if !isPremiumUser {
                showPremiumPaywall()
              }
            } label: {
              LockedWallpaperOptionRow(
                title: "Custom message",
                iconName: "text.quote",
                showsLock: !isPremiumUser
              )
            }
            .buttonStyle(.plain)
            .disabled(isPremiumUser)
          }
        }

        DailyWallpaperSettingsGroup(
          "Installation",
          footer:
            "iOS does not allow apps to set wallpaper directly. Test final application on a physical iPhone."
        ) {
          Button {
            isInstallationGuidePresented = true
          } label: {
            Label("Installation Guide", systemImage: "questionmark.circle")
              .font(AppFont.mono(12))
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
    }
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
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
        DailyWallpaperInstallationGuideView()
      }
      .presentationDetents([.large])
      .presentationDragIndicator(.visible)
    }
  }

  private func previewSettings(for template: DailyWallpaperTemplate) -> DailyWallpaperSettings {
    let accentColorName =
      isPremiumUser ? selectedAccentColor : DailyWallpaperSettingsStore.defaultAccentColorName

    return DailyWallpaperSettings(
      template: template,
      theme: selectedTheme,
      accentColorName: accentColorName,
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
      PremiumPaywallSheet(displayCloseButton: true, trigger: .settingsSupport)
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
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(AppFont.mono(11, weight: .bold))
        .foregroundColor(Color("text-secondary"))
        .textCase(.uppercase)

      content()

      if let footer {
        Text(footer)
          .font(AppFont.mono(11))
          .foregroundColor(Color("text-secondary"))
      }
    }
  }
}

private struct DailyWallpaperTemplatePager: View {
  @Binding var visibleTemplate: DailyWallpaperTemplate
  let selectedTemplate: DailyWallpaperTemplate
  let isPremiumUser: Bool
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
  let settings: DailyWallpaperSettings
  let onSelect: (DailyWallpaperTemplate) -> Void

  var body: some View {
    VStack(spacing: 12) {
      DailyWallpaperPreview(settings: settings)
        .overlay(alignment: .topTrailing) {
          if isLocked {
            Image(systemName: "lock.fill")
              .font(.system(size: 11, weight: .bold))
              .foregroundColor(Color("text-primary"))
              .padding(8)
              .background(Color("surface-muted").opacity(0.88))
              .clipShape(Circle())
              .padding(10)
          }
        }

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
  let onSelect: (DailyWallpaperTemplate) -> Void

  var body: some View {
    Button {
      onSelect(template)
    } label: {
      Image(systemName: isLocked ? "lock.fill" : "checkmark")
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(isSelected ? .surfaceMuted : .qsOrange)
        .frame(width: 20, height: 20)
        .background(isSelected ? .qsOrange : .qsOrange.opacity(0.1))
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
  let iconName: String
  let showsLock: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: iconName)
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(Color("text-secondary"))
        .frame(width: 22)

      Text(title)
        .font(AppFont.mono(12))
        .foregroundColor(Color("text-primary"))

      Spacer()

      if showsLock {
        Image(systemName: "lock.fill")
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(Color("text-tertiary"))
      }
    }
    .padding(.vertical, 4)
  }
}

private struct WallpaperAccentColorPicker: View {
  @Binding var selectedColor: String

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        ForEach(CalendarColorPickerSection.options) { option in
          Button {
            selectedColor = option.assetName
            Task {
              await hapticFeedback(.rigid)
            }
          } label: {
            ZStack {
              Circle()
                .fill(Color(option.assetName))
                .frame(width: 30, height: 30)

              Circle()
                .stroke(.white, lineWidth: selectedColor == option.assetName ? 2 : 0)
                .frame(width: 30, height: 30)
            }
            .frame(width: 44, height: 44)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(option.accessibilityName)
          .accessibilityHint(Text("Select wallpaper accent color"))
          .accessibilityAddTraits(selectedColor == option.assetName ? .isSelected : [])
        }
      }
      .padding(2)
      .padding(.horizontal, 10)
    }
    .padding(.vertical)
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
}

#Preview {
  NavigationStack {
    DailyWallpaperSetupView(customerInfo: nil)
  }
}
