# Kurs — Changelog

Release notes for **Kurs**, the iOS currency converter.

Repository — https://github.com/mishahatescode/kurs-ios
Active branch `polish-recent-pairs-and-fixes` — https://github.com/mishahatescode/kurs-ios/tree/polish-recent-pairs-and-fixes

`main` still holds only the initial commit; all work below is on the branch above.

## Unreleased — 2026-08-25

Commit `59a0aa1` — https://github.com/mishahatescode/kurs-ios/commit/59a0aa1

Five fixes from a round of device testing. All verified running on an iPhone 16e
simulator, not merely compiled.

### Fixed

**Appearance now applies the moment you pick it.**
The Light/Dark/System picker was only committed inside the Save handler, so the
control looked broken until you saved. It now applies on selection, and Cancel
restores the value the sheet was opened with. This had a second half: the window
went dark but the open Settings sheet stayed light, because a sheet is its own
presentation and does not inherit the window's scheme override. The scheme moved
to the window root and is re-applied to each of the four sheets.

**Cancel moved to the leading edge in the currency picker.**
Per Apple's HIG the trailing slot belongs to the confirming action. The app's
other three sheets already put Cancel on the left, so the picker was the sole
outlier.

**Data-source rows no longer re-wrap when the selection changes.**
The checkmark was rendered conditionally, so it occupied zero width when
unselected. Showing it narrowed the text column and re-flowed the wrapped summary
text. It is now always in the layout and only fades between opacity 0 and 1. The
identical defect was fixed in Rate Source and in the Formatting list.

**Custom rate removed.**
Dropped the `RateSource.custom` enum case, the text-field section, the conversion
branch, and the `kurs.customRate` persistence key. A previously saved `"Custom"`
raw value decodes to nil and falls back to Market rate, so existing installs
degrade cleanly rather than crashing.

**Offline mode works.**
Two separate bugs. The flag was never persisted — no key, no save, no load — so
it silently reset on every launch. And toggling it changed nothing on screen,
because the offline signal is driven by `loadError`, which was not set until the
next refresh attempt; the switch looked inert unless you happened to
pull-to-refresh. Both are handled in a new `setOffline()`, which also kicks off a
refresh when you switch back online.

### Scope

9 files changed, +97 / −91.

`ContentView` · `KursApp` · `AppState` · `Currency` · `PersistenceService` ·
`CurrencyPickerSheet` · `DataSourcesView` · `RateSourceView` · `SettingsView`

### Known, not addressed

The converter still allows the same currency on both sides (EUR → EUR).
`recordCurrentPair()` correctly refuses to save such a pair, so this is a
display-only quirk — but the picker does not prevent choosing it.

## 339c584 — initial commit

Kurs iOS currency converter — SwiftUI, iOS 16+, no third-party dependencies.
