import SwiftUI

// MARK: - Converter View (Main Card)

struct ConverterView: View {
  @EnvironmentObject var appState: AppState

  var body: some View {
    ZStack(alignment: .trailing) {
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

        Divider().padding(.leading, 16)

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

      // Swap button — pinned to the card's trailing edge, centered
      // over both rows (matches the prototype's fixed position).
      Button(action: {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          appState.swapCurrencies()
          appState.saveSettings()
        }
      }) {
        ZStack {
          Circle()
            .fill(Color.accentColor)
            .frame(width: 46, height: 46)
          Image(systemName: "arrow.up.arrow.down")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
        }
      }
      .buttonStyle(PressableButtonStyle())
      .padding(.trailing, 20)
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
    // Live-group the integer part as the user types (e.g. "2039774" reads as
    // "2,039,774"), then reattach whatever's been typed after the decimal
    // point as-is — grouping digits still being entered would fight the cursor.
    let locale = appState.numberLocale
    let sep = locale.decimalSeparator ?? "."
    guard let dotIndex = raw.firstIndex(of: ".") else {
      return groupedInteger(raw, locale: locale)
    }
    let intPart = String(raw[..<dotIndex])
    let fracPart = String(raw[raw.index(after: dotIndex)...])
    return groupedInteger(intPart, locale: locale) + sep + fracPart
  }

  private func groupedInteger(_ digits: String, locale: Locale) -> String {
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.numberStyle = .decimal
    formatter.usesGroupingSeparator = true
    formatter.maximumFractionDigits = 0
    let value = Double(digits) ?? 0
    return formatter.string(from: NSNumber(value: value)) ?? digits
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
        .padding(.trailing, 58)  // clear the floating swap button
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
    .contentShape(Rectangle())
    .onTapGesture { onRowTap() }
  }
}
