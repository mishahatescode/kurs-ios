import SwiftUI

// MARK: - Data Sources Sheet

struct DataSourcesView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss

  @State private var localEcbProviderID: String
  @State private var localMidMarketProviderID: String
  @State private var localRefreshMinutes: Int

  init(appState: AppState) {
    _localEcbProviderID = State(initialValue: appState.ecbProviderID)
    _localMidMarketProviderID = State(initialValue: appState.midMarketProviderID)
    _localRefreshMinutes = State(initialValue: appState.refreshIntervalMinutes)
  }

  private static let refreshOptions: [(minutes: Int, label: String)] = [
    (5, "Every 5 minutes"),
    (15, "Every 15 minutes"),
    (30, "Every 30 minutes"),
    (60, "Every hour"),
    (0, "Manual only"),
  ]

  var body: some View {
    NavigationStack {
      Form {
        // MARK: ECB Source
        Section {
          ForEach(RateProvider.allCases) { provider in
            providerRow(provider, isSelected: localEcbProviderID == provider.rawValue) {
              localEcbProviderID = provider.rawValue
            }
          }
        } header: {
          Text("ECB Source")
        } footer: {
          Text(
            countFooter(
              rates: appState.ecbRates,
              activeID: appState.ecbProviderID,
              localID: localEcbProviderID
            )
          )
          .font(.caption)
        }

        // MARK: Mid-market Source
        Section {
          ForEach(RateProvider.allCases) { provider in
            providerRow(provider, isSelected: localMidMarketProviderID == provider.rawValue) {
              localMidMarketProviderID = provider.rawValue
            }
          }
        } header: {
          Text("Mid-market Source")
        } footer: {
          Text(
            countFooter(
              rates: appState.liveRates,
              activeID: appState.midMarketProviderID,
              localID: localMidMarketProviderID
            )
          )
          .font(.caption)
        }

        // MARK: Refresh
        Section {
          ForEach(Self.refreshOptions, id: \.minutes) { option in
            Button {
              localRefreshMinutes = option.minutes
            } label: {
              HStack {
                Text(option.label)
                  .foregroundColor(.primary)
                Spacer()
                if localRefreshMinutes == option.minutes {
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
          Text("Refresh")
        } footer: {
          Text(
            "Rates always refresh on launch. Reopening the app after this much time has passed refreshes them again automatically."
          )
          .font(.caption)
        }
      }
      .navigationTitle("Data Sources")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Apply") {
            let providersChanged =
              localEcbProviderID != appState.ecbProviderID
              || localMidMarketProviderID != appState.midMarketProviderID
            appState.ecbProviderID = localEcbProviderID
            appState.midMarketProviderID = localMidMarketProviderID
            appState.refreshIntervalMinutes = localRefreshMinutes
            appState.saveSettings()
            if providersChanged {
              Task { await appState.refreshRates() }
            }
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
    }
  }

  private func providerRow(
    _ provider: RateProvider,
    isSelected: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(provider.displayName)
            .foregroundColor(.primary)
          Text(provider.host)
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
        if isSelected {
          Image(systemName: "checkmark")
            .foregroundColor(.accentColor)
            .font(.system(size: 14, weight: .semibold))
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func countFooter(rates: [String: Double], activeID: String, localID: String) -> String {
    guard activeID == localID else {
      return "Tap Apply to switch — currency coverage will refresh right after."
    }
    guard let count = appState.supportedCurrencyCount(in: rates) else {
      return "Coverage will show here after the first successful refresh."
    }
    return "\(count) of \(Currency.all.count) currencies available from this source."
  }
}
