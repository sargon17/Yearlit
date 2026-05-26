# Daily Wallpaper Shortcut

Yearlit can generate a dark **Daily Wallpaper** image for iOS Shortcuts. Yearlit only creates the image; Apple's **Set Wallpaper** shortcut action applies it.

## Setup

1. In Yearlit, open **Settings** → **Daily Wallpaper** → **Set Up Daily Wallpaper**.
2. Tap the Shortcuts link.
3. Create a **Time of Day** automation for **12:00 AM**, repeat **Daily**, and set it to **Run Immediately**.
4. Add the Yearlit action **Create Daily Wallpaper**.
5. Add Apple's **Set Wallpaper** action after it.
6. Use the wallpaper output from **Create Daily Wallpaper** as the image input.
7. Turn **Show Preview** off in the **Set Wallpaper** action.
8. Choose Lock Screen, Home Screen, or both.
9. If applying it to the Home Screen, turn **Blur** off.

## Notes

- The first version is dark-only.
- The generated image follows the Year widget's year-progress data: elapsed days, today, future days, percent complete, and days left.
- The automation must run through Shortcuts because iOS does not let apps silently set wallpapers directly.
- Test final wallpaper application on a physical iPhone. Simulator can show custom photo wallpapers as black even when the generated image is valid.
- Delete older **Generate Daily Wallpaper** or **Save Daily Wallpaper to Photos** actions from existing shortcuts.
- If the preview shows the grid but the applied wallpaper looks blank, turn **Show Preview** off in **Set Wallpaper**.
