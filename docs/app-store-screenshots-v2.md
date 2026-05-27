# App Store Screenshots V2 — Yearlit

Source: `app-store-screenshot-optimization-playbook-gpt-5-pro-v-1.pdf` + current `develop` codebase.

## Strategy

Yearlit should not sell “habit tracking” as a generic utility. The screenshots should sell the emotional job:

> “I keep restarting. I need small proof that I can trust myself again.”

Use a tight problem → solution → outcome story. The first 3 screenshots must carry the conversion argument because most store visitors will not scroll further.

## Visual system

- Format: iPhone 6.9” portrait App Store screenshots.
- Count: 10 screenshots for Apple’s maximum slot usage.
- Style: dark, high-contrast, minimal, with one strong orange/brand accent.
- Typography: huge headline, short subline, readable at App Store thumbnail size.
- Device/UI: real Yearlit screens in device mockups or clean cropped UI panels.
- Avoid: tiny UI dumps, generic “Features” labels, fake testimonials, “#1”, “free”, exaggerated outcomes.
- Recommended composition: headline top 35%, app UI/device center, short support line or proof cue bottom.

## Demo setup

Use **Developer mode** and the **Marketing demo calendar** tooling where possible.

Suggested demo calendars:

- `Daily Training` — daily binary, orange, ~70–80% filled year, current streak 18.
- `Read 1 page` — daily binary, emerald/green, low-pressure starter habit.
- `Write 3 lines` — daily binary, blue/purple, shows multiple tiny habits.
- Optional `Meditate 2 min` — daily binary, calm color.

Recommended visible states:

- A partially filled year grid with enough dots to feel real, not perfect.
- Today marked clearly.
- A short streak milestone / stats state when possible.
- Widget previews from `WidgetsShowcaseView`.
- Daily Wallpaper / Year Progress screen if available from Settings.

## Screenshot set

### 1. Your year starts today

**Headline:** Your year starts today

**Subline:** Not January 1st. The day you show up.

**Primary app visual:** `EmotionalHook` / year dot grid visual, ideally with a clean Yearlit app icon accent.

**Purpose:** Stop the scroll with Yearlit’s strongest belief. This is emotional positioning, not a feature tour.

**Notes:** This should feel like a manifesto. Keep it simple and bold.

---

### 2. One dot. One promise kept.

**Headline:** One dot. One promise kept.

**Subline:** Tap the day when you do the habit.

**Primary app visual:** Main calendar detail screen (`CustomCalendarView`) for `Daily Training`, with today completed and a visible year grid.

**Purpose:** Explain the core mechanic in one second.

**Notes:** This is the most important product-clarity screenshot. Show the grid large enough to understand without zooming.

---

### 3. Make habits too small to fail

**Headline:** Make habits too small to fail

**Subline:** Start with 5 minutes, 1 page, or 3 lines.

**Primary app visual:** Onboarding `TinyHabitSelectionView` with options like `Move for 5 minutes`, `Read 1 page`, `Write 3 lines`.

**Purpose:** Differentiate Yearlit from intense productivity apps. The app is about sustainable consistency, not pressure.

**Notes:** This should make the user think: “I could actually do that.”

---

### 4. Watch consistency become visible

**Headline:** Watch consistency become visible

**Subline:** Your effort turns into a year you can see.

**Primary app visual:** A mature `Daily Training` calendar with many filled dots across the year.

**Purpose:** Show the payoff of the core loop: repeated tiny actions become visible proof.

**Notes:** This is the outcome screenshot. Make the filled grid visually satisfying.

---

### 5. Track the streak without worshipping it

**Headline:** Track the streak. Keep the trust.

**Subline:** See current, longest, and active days.

**Primary app visual:** `CalendarStatisticsView` showing `Current`, `Longest`, `Active Days`, and completion rate.

**Purpose:** Show analytics while staying aligned with the brand: progress without toxic pressure.

**Notes:** If the UI has locked premium analytics, either use a premium state or crop to the basic streak/stat tiles.

---

### 6. Your habits, on your Home Screen

**Headline:** Keep progress where you see it

**Subline:** Add Yearlit widgets for habits, streaks, and year progress.

**Primary app visual:** `WidgetsShowcaseView` with Year Progress, Habit Progress, and Streak widgets.

**Purpose:** Widgets are a major differentiator and a strong conversion asset.

**Notes:** Use a Home Screen-style background if the design supports it, but don’t imply widgets are auto-installed.

---

### 7. See the year move every day

**Headline:** See the year move every day

**Subline:** Year Progress shows days passed and days left.

**Primary app visual:** Year Progress widget or Daily Wallpaper / Year Progress screen.

**Purpose:** Expand the product beyond habit check-ins into year-level awareness.

**Notes:** This screenshot can be more atmospheric. It should still remain readable and concrete.

---

### 8. Gentle reminders, not noise

**Headline:** Gentle reminders, not noise

**Subline:** Get nudged only when it helps you return.

**Primary app visual:** Notification permission screen or calendar notification settings.

**Purpose:** Handle the reminder objection: users want help, not spam.

**Notes:** If showing the iOS permission prompt is visually weak, show Yearlit’s own reminder settings instead.

---

### 9. Reflect without overthinking it

**Headline:** Reflect without overthinking it

**Subline:** Review your year, patterns, and progress.

**Primary app visual:** `AllCalendarsRecapView` / `Overview` with year grid + stats.

**Purpose:** Show depth for users who want more than a checkbox tracker.

**Notes:** This can target more analytical users, so it belongs later in the sequence.

---

### 10. Start with the smallest proof

**Headline:** Start with the smallest proof

**Subline:** Pick one tiny habit and mark Day 1.

**Primary app visual:** `FirstDotView` after “Proof added.” with the first dot visible.

**Purpose:** End with a low-friction CTA. The app feels easy to start, not like a setup burden.

**Notes:** This screenshot supports conversion by reducing activation anxiety.

## First 3 search/gallery variants

If testing a bolder first impression, use this first-three sequence instead:

1. **Stop restarting your year**
   Subline: Start again with one tiny dot.
2. **Make habits too small to fail**
   Subline: 5 minutes counts. 1 page counts.
3. **Watch self-trust come back**
   Subline: Build visible proof, one day at a time.

This variant is more pain-led. The default set is more brand-led and calmer.

## Caption/localization notes

Keep each headline short enough for localization:

- Aim for 4–7 words.
- Avoid idioms that translate poorly.
- Keep line breaks manual and intentional.
- Prefer concrete words: `dot`, `day`, `habit`, `streak`, `year`, `widget`, `reminder`.

## Production checklist

- [ ] Capture 6.9” iPhone portrait screenshots.
- [ ] Use clean screenshot mode / hide developer controls.
- [ ] Fill Marketing demo calendars with deterministic realistic data.
- [ ] Verify all text is readable at App Store thumbnail size.
- [ ] Ensure screenshots 1–3 tell the full story alone.
- [ ] Keep captions benefit-led, not feature labels.
- [ ] Avoid unsupported claims and Apple-rejection-sensitive wording.
- [ ] Export localized source text separately before translating.
