import RevenueCat
import SwiftUI
import SwiftfulRouting

struct DailyWallpaperSetupView: View {
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
        themeSection
        accentColorSection
        messageSection
        installationSection
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

  private var themeSection: some View {
    DailyWallpaperSettingsGroup("Theme") {
      WallpaperThemePicker(
        selectedTheme: selectedTheme,
        accentColor: effectiveAccentColor
      ) { theme in
        selectedTheme = theme
        DailyWallpaperSettingsStore.saveTheme(theme)
      }
    }
  }

  private var accentColorSection: some View {
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
  }

  private var messageSection: some View {
    DailyWallpaperSettingsGroup("Message") {
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
  }

  private var installationSection: some View {
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

  private func previewSettings(for template: DailyWallpaperTemplate) -> DailyWallpaperSettings {
    DailyWallpaperSettings(
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
      PremiumPaywallSheet(displayCloseButton: true, trigger: .settingsSupport)
    }
  }
}

#Preview {
  NavigationStack {
    DailyWallpaperSetupView(customerInfo: nil)
  }
}
