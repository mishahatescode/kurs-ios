import SwiftUI

// MARK: - Data Source Sheet

/// One feed powers every rate in the app. The three options differ in who
/// publishes the numbers, how often, and how many currencies they cover —
/// so each is described in plain language rather than by its API hostname.
struct DataSourcesView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss

  @State private var localProviderID: String

  init(appState: AppState) {
    _localProviderID = State(initialValue: appState.providerID)
  }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          ForEach(RateProvider.allCases) { provider in
            Button {
              localProviderID = provider.rawValue
            } label: {
              HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                  Text(provider.displayName)
                    .foregroundColor(.primary)
                  Text(provider.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if localProviderID == provider.rawValue {
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
          Text("Where rates come from")
        } footer: {
          Text(coverageFooter)
            .font(.caption)
        }
      }
      .navigationTitle("Data Source")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Apply") {
            let changed = localProviderID != appState.providerID
            appState.providerID = localProviderID
            appState.saveSettings()
            if changed {
              Task { await appState.refreshRates() }
            }
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
    }
  }

  private var coverageFooter: String {
    guard localProviderID == appState.providerID else {
      return "Tap Apply to switch — rates and currency coverage refresh right after."
    }
    guard let count = appState.supportedCurrencyCount else {
      return "Coverage will show here after the first successful refresh."
    }
    return "\(count) of \(Currency.all.count) currencies available from this source."
  }
}
