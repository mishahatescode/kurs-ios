import SwiftUI

@main
struct KursApp: App {
  @StateObject private var appState = AppState()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(appState)
        // Applied at the window root, not inside ContentView — a sheet is its
        // own presentation, so a scheme set further down left the open
        // Settings sheet on the old theme while the page behind it changed.
        .preferredColorScheme(appState.isDarkMode.map { $0 ? .dark : .light })
    }
  }
}

// MARK: - Appearance Propagation

extension View {
  /// A sheet is presented in its own context and does not inherit the window's
  /// scheme override, so the appearance choice has to be re-applied to each
  /// sheet's content — otherwise switching to Dark repaints the window behind
  /// the sheet while the sheet itself stays light.
  func kursAppearance(_ isDarkMode: Bool?) -> some View {
    preferredColorScheme(isDarkMode.map { $0 ? .dark : .light })
  }
}
