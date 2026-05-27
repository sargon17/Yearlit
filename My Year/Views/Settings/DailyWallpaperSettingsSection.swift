import AppIntents
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
  @State private var selectedTheme: DailyWallpaperTheme
  @State private var selectedAccentColor: String
  @State private var messageText: String

  private var isPremiumUser: Bool {
    isPremium(customerInfo: customerInfo)
      || (customerInfo == nil && DailyWallpaperSettingsStore.hasCachedPremiumAccess())
  }

  private var selectedTemplateSupportsMessage: Bool {
    selectedTemplate.supportsMessage && isPremiumUser
  }

  private var previewSettings: DailyWallpaperSettings {
    guard isPremiumUser else {
      return DailyWallpaperSettings(
        template: .classic,
        theme: selectedTheme,
        accentColorName: DailyWallpaperSettingsStore.defaultAccentColorName,
        message: nil
      )
    }

    return DailyWallpaperSettings(
      template: selectedTemplate,
      theme: selectedTheme,
      accentColorName: selectedAccentColor,
      message: selectedTemplate.supportsMessage ? messageText : nil
    )
  }

  init(customerInfo: CustomerInfo?) {
    let settings = DailyWallpaperSettingsStore.savedSettings()
    self.customerInfo = customerInfo
    _selectedTemplate = State(initialValue: settings.template)
    _selectedTheme = State(initialValue: settings.theme)
    _selectedAccentColor = State(initialValue: settings.accentColorName)
    _messageText = State(initialValue: settings.message ?? "")
  }

  var body: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: 12) {
          Text("Shortcut setup")
            .font(AppFont.mono(16, weight: .bold))
            .foregroundColor(Color("text-primary"))

          Text("Choose the wallpaper in Yearlit. The Shortcut keeps using Create Daily Wallpaper.")
            .font(AppFont.mono(12))
            .foregroundColor(Color("text-secondary"))
        }
        .padding(.vertical, 4)
      }

      Section(header: Text("Preview")) {
        DailyWallpaperPreview(settings: previewSettings)
      }

      Section(header: Text("Template")) {
        templateButtons
      }

      Section(header: Text("Theme")) {
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

      Section {
        if isPremiumUser {
          WallpaperAccentColorPicker(selectedColor: $selectedAccentColor)
        } else {
          Button {
            showPremiumPaywall()
          } label: {
            WallpaperOptionRow(
              title: "Custom accent color",
              iconName: "paintpalette.fill",
              isSelected: false,
              isLocked: true
            )
          }
          .buttonStyle(.plain)
        }
      } header: {
        Text("Accent Color")
      } footer: {
        Text("The accent color changes the current-day dot and highlighted progress number.")
      }

      Section {
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
            WallpaperOptionRow(
              title: "Custom message",
              iconName: "text.quote",
              isSelected: false,
              isLocked: !isPremiumUser
            )
          }
          .buttonStyle(.plain)
          .disabled(isPremiumUser)
        }
      } header: {
        Text("Message")
      } footer: {
        Text("Premium message templates render up to two centered lines, 40 characters total.")
      }

      Section(header: Text("Actions")) {
        SetupStepRow(
          number: 1,
          title: "Create Daily Wallpaper",
          subtitle: "Yearlit generates the selected wallpaper."
        )
        SetupStepRow(
          number: 2,
          title: "Set Wallpaper",
          subtitle: "Use the Daily Wallpaper output. Turn Show Preview off."
        )
      }

      Section(header: Text("Automation")) {
        SetupStepRow(number: 1, title: "Time of Day", subtitle: "Set it to 12:00 AM.")
        SetupStepRow(number: 2, title: "Repeat Daily", subtitle: "Run the wallpaper refresh every day.")
        SetupStepRow(number: 3, title: "Run Immediately", subtitle: "Do not ask before running.")
      }

      Section {
        ShortcutsLink()
          .shortcutsLinkStyle(.automatic)
      } footer: {
        Text(
          "iOS does not allow apps to set wallpaper directly. Test final application on a physical iPhone."
        )
      }
    }
    .scrollContentBackground(.hidden)
    .surfaceBackground(Color("surface-muted"), ignoresSafeArea: true)
    .navigationTitle("Daily Wallpaper")
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

  @ViewBuilder
  private var templateButtons: some View {
    ForEach(DailyWallpaperTemplate.allCases) { template in
      Button {
        selectTemplate(template)
      } label: {
        WallpaperOptionRow(
          title: template.displayName,
          iconName: template.systemImageName,
          isSelected: selectedTemplate == template,
          isLocked: template.isPremium && !isPremiumUser
        )
      }
      .buttonStyle(.plain)
    }
  }

  private func selectTemplate(_ template: DailyWallpaperTemplate) {
    guard isPremiumUser || !template.isPremium else {
      showPremiumPaywall()
      return
    }

    selectedTemplate = template
    DailyWallpaperSettingsStore.saveTemplate(template)
  }

  private func showPremiumPaywall() {
    router.showScreen(.sheet) { _ in
      PaywallView(displayCloseButton: true)
        .onAppear {
          Analytics.shared.trackPaywallViewed(trigger: .settingsSupport)
        }
    }
  }
}

private struct WallpaperOptionRow: View {
  let title: String
  let iconName: String
  let isSelected: Bool
  let isLocked: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: iconName)
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(isSelected ? Color("qs-orange") : Color("text-secondary"))
        .frame(width: 22)

      Text(title)
        .font(AppFont.mono(12, weight: isSelected ? .bold : .regular))
        .foregroundColor(Color("text-primary"))

      Spacer()

      if isLocked {
        Image(systemName: "lock.fill")
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(Color("text-tertiary"))
      } else if isSelected {
        Image(systemName: "checkmark")
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(Color("qs-orange"))
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
  @State private var image: UIImage?

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 28)
        .fill(Color("surface-muted"))

      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      }
    }
    .aspectRatio(430 / 932, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 28))
    .overlay {
      RoundedRectangle(cornerRadius: 28)
        .stroke(Color("text-primary").opacity(0.12), lineWidth: 1)
    }
    .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 8)
    .frame(maxWidth: 210)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 8)
    .task(id: settings) {
      image = DailyWallpaperRenderer.renderPreview(settings: settings)
    }
  }
}

private struct SetupStepRow: View {
  let number: Int
  let title: String
  let subtitle: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Text(number.description)
        .font(AppFont.mono(12, weight: .bold))
        .foregroundColor(Color("surface-muted"))
        .frame(width: 24, height: 24)
        .background(Color("qs-orange"))
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(AppFont.mono(13, weight: .bold))
          .foregroundColor(Color("text-primary"))

        Text(subtitle)
          .font(AppFont.mono(11))
          .foregroundColor(Color("text-secondary"))
      }
    }
    .padding(.vertical, 4)
  }
}

extension DailyWallpaperTheme {
  fileprivate var displayName: String {
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
