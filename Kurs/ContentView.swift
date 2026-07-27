import SwiftUI

// MARK: - Content View

struct ContentView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    ZStack(alignment: .bottom) {
      mainContent
      toastOverlay
    }
    .preferredColorScheme(appState.isDarkMode.map { $0 ? .dark : .light })
    .sheet(isPresented: $appState.showCurrencyPicker) {
      CurrencyPickerSheet(pickingForSource: appState.pickingForSource)
        .environmentObject(appState)
    }
    .sheet(isPresented: $appState.showRateSource) {
      RateSourceView(appState: appState)
        .environmentObject(appState)
    }
    .sheet(isPresented: $appState.showSettings) {
      SettingsView(appState: appState)
        .environmentObject(appState)
    }
    .onChange(of: scenePhase) { newPhase in
      if newPhase == .active {
        Task { await appState.refreshIfStale() }
      }
    }
  }

  // MARK: - Main Content

  private var mainContent: some View {
    VStack(spacing: 0) {
      // Navigation bar
      navBar

      // Scrollable body
      ScrollView {
        RefreshControl(coordinateSpaceName: "pullToRefresh") {
          Task { await appState.refreshRates() }
        }

        LazyVStack(spacing: 16) {
          // Converter card
          ConverterView()
            .environmentObject(appState)
            .padding(.top, 2)

          // Rate line + "updated ago" chip
          rateInfoSection

          // Recent pairs
          RecentPairsView()
            .environmentObject(appState)

          Spacer(minLength: 20)
        }
      }
      .coordinateSpace(name: "pullToRefresh")
      .background(Color(uiColor: .systemGroupedBackground))

      // Keypad (always visible)
      NumericKeypad(
        activeCurrency: appState.isSourceActive
          ? appState.sourceCurrency
          : appState.targetCurrency
      )
      .environmentObject(appState)
    }
    .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
  }

  // MARK: - Navigation Bar

  private var navBar: some View {
    HStack {
      Text("Kurs")
        .font(.system(size: 28, weight: .bold, design: .rounded))

      Spacer()

      // Settings button
      Button {
        appState.showSettings = true
      } label: {
        Image(systemName: "gearshape")
          .font(.system(size: 18))
          .foregroundColor(.accentColor)
      }
      .buttonStyle(PressableButtonStyle())
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .padding(.bottom, 8)
    .background(Color(uiColor: .systemGroupedBackground))
  }

  // MARK: - Rate Line + "Updated Ago" Chip

  private var rateInfoSection: some View {
    VStack(spacing: 9) {
      // Rate line — plain centered text, taps through to Rate Source.
      Button {
        appState.showRateSource = true
      } label: {
        if let err = appState.loadError {
          HStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
              .font(.system(size: 12))
            Text(err)
              .font(.system(size: 13, weight: .medium))
          }
          .foregroundColor(.orange)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
        } else {
          Text(appState.rateInfoString)
            .font(.system(size: 13))
            .foregroundColor(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
      }
      .buttonStyle(PressableButtonStyle())

      // Refresh chip — "Rates updated 3 min ago", ticks live.
      Button {
        Task { await appState.refreshRates() }
      } label: {
        TimelineView(.periodic(from: .now, by: 30)) { context in
          HStack(spacing: 6) {
            if appState.isLoading {
              ProgressView()
                .scaleEffect(0.7)
                .tint(.accentColor)
            } else {
              Image(systemName: "arrow.clockwise")
                .font(.system(size: 12, weight: .semibold))
            }
            Text(
              appState.isLoading
                ? "Updating…" : "Rates updated \(appState.updatedAgoText(now: context.date))"
            )
            .font(.system(size: 13, weight: .medium))
          }
        }
        .foregroundColor(.accentColor)
        .padding(.horizontal, 13)
        .frame(minHeight: 32)
        .background(Color.accentColor.opacity(0.12))
        .clipShape(Capsule())
      }
      .buttonStyle(PressableButtonStyle())
    }
    .padding(.horizontal, 20)
  }

  // MARK: - Toast Overlay

  private var toastOverlay: some View {
    Group {
      if let message = appState.toastMessage {
        VStack {
          Spacer()
          Text(message)
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(uiColor: .label).opacity(0.85))
            .foregroundColor(Color(uiColor: .systemBackground))
            .cornerRadius(24)
            .shadow(radius: 8)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: appState.toastMessage)
      }
    }
  }
}

// MARK: - Pull to Refresh Helper

struct RefreshControl: View {
  let coordinateSpaceName: String
  let action: () -> Void
  @State private var isRefreshing = false

  var body: some View {
    GeometryReader { geo in
      // minY is relative to the ScrollView's own coordinate space, so it's
      // ~0 at rest and only grows positive while the user actively pulls
      // past the top — using `.global` here made this permanently "true"
      // (the scroll view already sits below the nav bar/safe area on
      // screen), which fired refreshRates() in an infinite ~1.5s loop.
      let pullDistance = geo.frame(in: .named(coordinateSpaceName)).minY
      if pullDistance > 60 && !isRefreshing {
        Spacer()
          .onAppear {
            isRefreshing = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
              isRefreshing = false
            }
          }
      }
    }
    .frame(height: 0)
  }
}
