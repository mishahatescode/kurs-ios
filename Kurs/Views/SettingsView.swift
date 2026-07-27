import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var systemColorScheme

  // Local copies
  @State private var localDarkMode: Int  // 0=system, 1=light, 2=dark
  @State private var localOffline: Bool

  init(appState: AppState) {
    let dm = appState.isDarkMode
    _localDarkMode = State(initialValue: dm == nil ? 0 : (dm! ? 2 : 1))
    _localOffline = State(initialValue: appState.isOffline)
  }

  var body: some View {
    NavigationStack {
      Form {
        // MARK: Appearance
        Section {
          Picker("Appearance", selection: $localDarkMode) {
            Text("System").tag(0)
            Text("Light").tag(1)
            Text("Dark").tag(2)
          }
          .pickerStyle(.segmented)
          .padding(.vertical, 4)
        } header: {
          Text("Appearance")
        }

        // MARK: Network
        Section {
          Toggle(isOn: $localOffline) {
            Label {
              VStack(alignment: .leading, spacing: 2) {
                Text("Offline Mode")
                Text("Use cached or seed rates only")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            } icon: {
              Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
            }
          }
        } header: {
          Text("Network")
        }

        // MARK: Rates Info
        Section {
          RateInfoRow(label: "ECB Source", value: "api.frankfurter.app")
          RateInfoRow(label: "Live Source", value: "open.er-api.com")
          RateInfoRow(label: "Refresh", value: "On launch & 15 min interval")
          RateInfoRow(label: "Currencies", value: "\(Currency.all.count) supported")
        } header: {
          Text("Exchange Rates")
        }

        // MARK: About
        Section {
          RateInfoRow(label: "Version", value: "1.0.0")
          RateInfoRow(label: "Bundle", value: "com.onedollarapps.kurs")
          Link(destination: URL(string: "https://frankfurter.app")!) {
            HStack {
              Text("Frankfurter API")
                .foregroundColor(.primary)
              Spacer()
              Image(systemName: "arrow.up.right.square")
                .foregroundColor(.accentColor)
            }
          }
          Link(destination: URL(string: "https://open.er-api.com")!) {
            HStack {
              Text("Open ER API")
                .foregroundColor(.primary)
              Spacer()
              Image(systemName: "arrow.up.right.square")
                .foregroundColor(.accentColor)
            }
          }
        } header: {
          Text("About")
        }

        // MARK: Reset
        Section {
          Button(role: .destructive) {
            appState.clearRecentPairs()
            appState.clearRecentCurrencies()
            appState.showToast("Cleared recent pairs")
            dismiss()
          } label: {
            Label("Clear Recent Pairs", systemImage: "trash")
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") {
            // Apply appearance
            switch localDarkMode {
            case 1: appState.isDarkMode = false
            case 2: appState.isDarkMode = true
            default: appState.isDarkMode = nil
            }
            appState.isOffline = localOffline
            appState.saveSettings()
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
    }
  }
}

// MARK: - Helper Row

private struct RateInfoRow: View {
  let label: String
  let value: String

  var body: some View {
    HStack {
      Text(label)
        .foregroundColor(.secondary)
      Spacer()
      Text(value)
        .foregroundColor(.primary)
        .font(.system(size: 14))
        .multilineTextAlignment(.trailing)
    }
  }
}
