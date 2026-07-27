import SwiftUI

// MARK: - Currency Picker Sheet

struct CurrencyPickerSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let pickingForSource: Bool

    @State private var searchText: String = ""
    @FocusState private var searchFocused: Bool

    private var recentCurrencies: [Currency] {
        appState.recentCurrencies.compactMap { Currency.byCode[$0] }
    }

    private var filteredCurrencies: [Currency] {
        if searchText.isEmpty { return Currency.all }
        let q = searchText.lowercased()
        return Currency.all.filter {
            $0.code.lowercased().contains(q) ||
            $0.name.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Recents section
                if searchText.isEmpty && !recentCurrencies.isEmpty {
                    Section("Recent") {
                        ForEach(recentCurrencies) { currency in
                            CurrencyPickerRow(currency: currency, onSelect: { select(currency) })
                        }
                    }
                }

                // All / Search Results
                Section(searchText.isEmpty ? "All Currencies" : "Results") {
                    ForEach(filteredCurrencies) { currency in
                        CurrencyPickerRow(currency: currency, onSelect: { select(currency) })
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search currency…")
            .navigationTitle(pickingForSource ? "From" : "To")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func select(_ currency: Currency) {
        if pickingForSource {
            appState.sourceCurrency = currency
        } else {
            appState.targetCurrency = currency
        }
        appState.recordRecent(currency.code)
        appState.saveSettings()
        dismiss()
    }
}

// MARK: - Currency Picker Row

private struct CurrencyPickerRow: View {
    @EnvironmentObject var appState: AppState
    let currency: Currency
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(currency.flag)
                    .font(.system(size: 26))
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.code)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(currency.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if appState.isPinned(currency.code) {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                appState.togglePin(currency.code)
            } label: {
                Label(
                    appState.isPinned(currency.code) ? "Unpin" : "Pin",
                    systemImage: appState.isPinned(currency.code) ? "pin.slash" : "pin"
                )
            }
            .tint(.orange)
        }
    }
}
