import SwiftUI

// MARK: - Pinned Currencies View

struct PinnedCurrenciesView: View {
    @EnvironmentObject var appState: AppState
    @State private var isEditing = false

    var body: some View {
        if appState.pinnedCurrencies.isEmpty {
            emptyState
        } else {
            pinnedList
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "pin.slash")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
            Text("No pinned currencies")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Long-press a currency to pin it")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    // MARK: - Pinned List

    private var pinnedList: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Pinned")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation { isEditing.toggle() }
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // List
            VStack(spacing: 0) {
                ForEach(Array(appState.pinnedCurrencies.enumerated()), id: \.element) { idx, code in
                    if let currency = Currency.byCode[code] {
                        PinnedCurrencyRow(currency: currency, isEditing: isEditing)
                        if idx < appState.pinnedCurrencies.count - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Pinned Currency Row

private struct PinnedCurrencyRow: View {
    @EnvironmentObject var appState: AppState
    let currency: Currency
    let isEditing: Bool

    var convertedAmount: Double {
        appState.pinnedAmount(for: currency.code)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Edit controls
            if isEditing {
                Button(role: .destructive) {
                    withAnimation {
                        appState.pinnedCurrencies.removeAll { $0 == currency.code }
                        appState.saveSettings()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            // Flag + code
            Text(currency.flag)
                .font(.system(size: 26))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(currency.code)
                    .font(.system(size: 15, weight: .semibold))
                Text(currency.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Amount
            Text(appState.formatAmount(convertedAmount, currency: currency))
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = appState.formatAmount(convertedAmount, currency: currency)
                        appState.showToast("Copied \(currency.code) amount")
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }

            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                // Tap to set as target
                appState.targetCurrency = currency
                appState.isSourceActive = true
                appState.recordRecent(currency.code)
                appState.saveSettings()
            }
        }
        .onLongPressGesture {
            appState.togglePin(currency.code)
        }
    }
}
