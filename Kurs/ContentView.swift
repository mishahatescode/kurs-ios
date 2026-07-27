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
        .onChange(of: scenePhase) { _, newPhase in
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
                RefreshControl {
                    Task { await appState.refreshRates() }
                }

                LazyVStack(spacing: 16) {
                    // Rate info chip
                    rateInfoChip
                        .padding(.top, 8)

                    // Converter card
                    ConverterView()
                        .environmentObject(appState)

                    // Pinned currencies
                    PinnedCurrenciesView()
                        .environmentObject(appState)

                    Spacer(minLength: 20)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))

            // Keypad (always visible)
            NumericKeypad(activeCurrency: appState.isSourceActive
                          ? appState.sourceCurrency
                          : appState.targetCurrency)
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

            // Rate source button
            Button {
                appState.showRateSource = true
            } label: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.trailing, 8)

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

    // MARK: - Rate Info Chip

    private var rateInfoChip: some View {
        HStack(spacing: 8) {
            if appState.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.accentColor)
            } else {
                Button {
                    Task { await appState.refreshRates() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(PressableButtonStyle())
            }

            if let err = appState.loadError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 12))
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                Text(appState.rateInfoString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)

            // Source badge
            Text(appState.rateSource.displayName)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.15))
                .foregroundColor(.accentColor)
                .cornerRadius(6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .onTapGesture {
            appState.showRateSource = true
        }
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
    let action: () -> Void
    @State private var isRefreshing = false

    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: .global).minY > 60 && !isRefreshing {
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
