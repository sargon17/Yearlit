# Daily Wallpaper Shortcut

Yearlit can generate a **Daily Wallpaper** image for iOS Shortcuts. Yearlit only creates the image; Apple's **Set Wallpaper** shortcut action applies it.

## Setup

1. In Yearlit, open **Settings** → **Daily Wallpaper** → **Set Up Daily Wallpaper**.
2. Choose the **Daily Wallpaper** template, light or dark theme, and any available premium customization.
3. Tap the Shortcuts link.
4. Create a **Time of Day** automation for **12:00 AM**, repeat **Daily**, and set it to **Run Immediately**.
5. Add the Yearlit action **Create Daily Wallpaper**.
6. Add Apple's **Set Wallpaper** action after it.
7. Use the wallpaper output from **Create Daily Wallpaper** as the image input.
8. Turn **Show Preview** off in the **Set Wallpaper** action.
9. Choose Lock Screen, Home Screen, or both.
10. If applying it to the Home Screen, turn **Blur** off.

## Notes

- The **Daily Wallpaper Shortcut** does not need template, theme, color, or message parameters. It always runs **Create Daily Wallpaper**.
- The free Classic **Daily Wallpaper template** supports manual light and dark themes.
- Premium templates can use a custom accent color and, when the selected template supports it, a custom message.
- The generated image follows the Year widget's year-progress data: elapsed days, today, future days, percent complete, and days left.
- The automation must run through Shortcuts because iOS does not let apps silently set wallpapers directly.
- Test final wallpaper application on a physical iPhone. Simulator can show custom photo wallpapers as black even when the generated image is valid.
- Delete older **Generate Daily Wallpaper** or **Save Daily Wallpaper to Photos** actions from existing shortcuts.
- If the preview shows the grid but the applied wallpaper looks blank, turn **Show Preview** off in **Set Wallpaper**.
