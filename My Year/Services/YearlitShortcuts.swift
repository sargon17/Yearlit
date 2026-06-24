import AppIntents

struct YearlitShortcuts: AppShortcutsProvider {
  static var shortcutTileColor: ShortcutTileColor = .orange

  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: CreateDailyWallpaperIntent(),
      phrases: [
        "Create \(.applicationName) daily wallpaper",
        "Create \(.applicationName) wallpaper"
      ],
      shortTitle: "Daily Wallpaper",
      systemImageName: "calendar"
    )

    AppShortcut(
      intent: QuickAddCalendarIntent(),
      phrases: [
        "Check in with \(.applicationName)",
        "Quick add in \(.applicationName)"
      ],
      shortTitle: "Check In",
      systemImageName: "checkmark.circle"
    )

    AppShortcut(
      intent: CheckInCalendarIntent(),
      phrases: [
        "Check in a calendar with \(.applicationName)",
        "Log a check in with \(.applicationName)"
      ],
      shortTitle: "Log Check In",
      systemImageName: "plus.circle"
    )
  }
}
