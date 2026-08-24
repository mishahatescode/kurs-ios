import SwiftUI

// MARK: - Currency Picker Sheet

struct CurrencyPickerSheet: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  let pickingForSource: Bool

  @State private var searchText: String = ""
  @FocusState private var searchFocused: Bool

  private var pinnedCurrencies: [Currency] {
    appState.pinnedCurrencies.compactMap { Currency.byCode[$0] }
  }

  /// Recents minus anything already pinned — a pinned currency is always
  /// visible at the top, so repeating it just below is noise.
  private var recentCurrencies: [Currency] {
    appState.recentCurrencies
      .filter { !appState.isPinned($0) }
      .compactMap { Currency.byCode[$0] }
  }

  private var filteredCurrencies: [Currency] {
    if searchText.isEmpty { return Currency.all }
    let q = searchText.lowercased()
    return Currency.all.filter {
      $0.code.lowercased().contains(q) || $0.name.lowercased().contains(q)
    }
  }

  var body: some View {
    NavigationStack {
      List {
        if searchText.isEmpty && !pinnedCurrencies.isEmpty {
          Section("Pinned") {
            ForEach(pinnedCurrencies) { currency in
              CurrencyPickerRow(currency: currency, onSelect: { select(currency) })
            }
          }
        }

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
      .searchable(
        text: $searchText, placement: .navigationBarDrawer(displayMode: .always),
        prompt: "Search currency…"
      )
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
    appState.recordCurrentPair()
    appState.saveSettings()
    dismiss()
  }
}

// MARK: - Currency Picker Row

private struct CurrencyPickerRow: View {
  @EnvironmentObject var appState: AppState
  let currency: Currency
  let onSelect: () -> Void

  private var isPinned: Bool { appState.isPinned(currency.code) }

  var body: some View {
    // The row is a plain HStack rather than a Button so the star can be its
    // own independently-tappable control inside it; a Button-in-Button
    // swallows the inner tap.
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

      Button {
        withAnimation { appState.togglePin(currency.code) }
      } label: {
        Image(systemName: isPinned ? "star.fill" : "star")
          .font(.system(size: 15))
          .foregroundColor(isPinned ? .yellow : Color(uiColor: .tertiaryLabel))
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .buttonStyle(.borderless)
      .accessibilityLabel(isPinned ? "Unpin \(currency.code)" : "Pin \(currency.code)")
    }
    .contentShape(Rectangle())
    .onTapGesture { onSelect() }
  }
}
