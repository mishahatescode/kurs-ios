import SwiftUI

// MARK: - Converter View (Main Card)

struct ConverterView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Source row
            CurrencyInputRow(
                currency: appState.sourceCurrency,
                valueString: sourceDisplayString,
                isActive: appState.isSourceActive,
                onCurrencyTap: {
                    appState.pickingForSource = true
                    appState.showCurrencyPicker = true
                },
                onRowTap: {
                    appState.isSourceActive = true
                }
            )

            // Divider + Swap button
            ZStack {
                Divider()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        appState.swapCurrencies()
                        appState.saveSettings()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .frame(width: 40, height: 40)
                            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(PressableButtonStyle())
            }

            // Target row
            CurrencyInputRow(
                currency: appState.targetCurrency,
                valueString: targetDisplayString,
                isActive: !appState.isSourceActive,
                onCurrencyTap: {
                    appState.pickingForSource = false
                    appState.showCurrencyPicker = true
                },
                onRowTap: {
                    appState.isSourceActive = false
                }
            )
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    // MARK: - Display Strings

    private var sourceDisplayString: String {
        if appState.isSourceActive {
            return displayInput(appState.amountString, currency: appState.sourceCurrency)
        } else {
            let val = appState.amount
            return appState.formatAmount(val, currency: appState.sourceCurrency)
        }
    }

    private var targetDisplayString: String {
        if !appState.isSourceActive {
            return displayInput(appState.amountString, currency: appState.targetCurrency)
        } else {
            let val = appState.convertedAmount
            return appState.formatAmount(val, currency: appState.targetCurrency)
        }
    }

    private func displayInput(_ raw: String, currency: Currency) -> String {
        // Show the raw input string (with locale decimal) during editing
        // but replace "." with the locale separator for display
        let sep = Locale.current.decimalSeparator ?? "."
        return raw.replacingOccurrences(of: ".", with: sep)
    }
}

// MARK: - Currency Input Row

private struct CurrencyInputRow: View {
    @EnvironmentObject var appState: AppState

    let currency: Currency
    let valueString: String
    let isActive: Bool
    let onCurrencyTap: () -> Void
    let onRowTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Currency selector button
            Button(action: onCurrencyTap) {
                HStack(spacing: 8) {
                    Text(currency.flag)
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(currency.code)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(currency.name)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(10)
            }
            .buttonStyle(PressableButtonStyle())

            Spacer()

            // Amount display
            Text(valueString)
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundColor(isActive ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .multilineTextAlignment(.trailing)
                .onTapGesture { onRowTap() }
                .onLongPressGesture {
                    // Copy to clipboard
                    let raw = valueString.replacingOccurrences(of: ",", with: ".")
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: "\u{00A0}", with: "")
                    UIPasteboard.general.string = raw
                    appState.showToast("Copied \(currency.code) \(valueString)")
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            isActive
                ? Color.accentColor.opacity(0.06)
                : Color.clear
        )
        .animation(.easeInOut(duration: 0.15), value: isActive)
        .contentShape(Rectangle())
        .onTapGesture { onRowTap() }
    }
}
