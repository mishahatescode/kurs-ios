import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var systemColorScheme

  // Local copies
  @State private var localDarkMode: Int  // 0=system, 1=light, 2=dark
  @State private var localOffline: Bool
  @State private var localNumberLocaleID: String
  @State private var showRateSource = false

  init(appState: AppState) {
    let dm = appState.isDarkMode
    _localDarkMode = State(initialValue: dm == nil ? 0 : (dm! ? 2 : 1))
    _localOffline = State(initialValue: appState.isOffline)
    _localNumberLocaleID = State(initialValue: appState.numberLocaleID)
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

        // MARK: Rate Source
        Section {
          Button {
            showRateSource = true
          } label: {
            HStack {
              Text("Rate Source")
                .foregroundColor(.primary)
              Spacer()
              Text(appState.rateSource.displayName)
                .foregroundColor(.secondary)
              Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
          }
        } header: {
          Text("Rate Source")
        } footer: {
          Text("Choose the plain market rate, a card/bank fee, or your own fixed rate.")
            .font(.caption)
        }

        // MARK: Formatting
        Section {
          ForEach(NumberLocaleOption.all) { option in
            Button {
              withAnimation { localNumberLocaleID = option.id }
            } label: {
              HStack {
                VStack(alignment: .leading, spacing: 2) {
                  Text(option.name)
                    .foregroundColor(.primary)
                  Text(Self.sampleFormat(for: option.id))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                }
                Spacer()
                if localNumberLocaleID == option.id {
                  Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14, weight: .semibold))
                }
              }
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        } header: {
          Text("Formatting")
        } footer: {
          Text(
            "Controls how amounts are grouped and separated — independent of your device's language."
          )
          .font(.caption)
        }

        // MARK: About
        Section {
          RateInfoRow(label: "Version", value: "1.0.0")
          RateInfoRow(label: "Bundle", value: "com.onedollarapps.kurs")
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
            appState.numberLocaleID = localNumberLocaleID
            appState.saveSettings()
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
      .sheet(isPresented: $showRateSource) {
        RateSourceView(appState: appState)
          .environmentObject(appState)
      }
    }
  }

  private static func sampleFormat(for localeID: String) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: localeID)
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: 1_234_567.89)) ?? ""
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
