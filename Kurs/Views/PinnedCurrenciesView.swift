import SwiftUI

// MARK: - Recent Pairs View

struct RecentPairsView: View {
  @EnvironmentObject var appState: AppState

  var body: some View {
    if appState.recentPairs.isEmpty {
      emptyState
    } else {
      recentList
    }
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 8) {
      Image(systemName: "clock.arrow.circlepath")
        .font(.system(size: 28))
        .foregroundColor(.secondary)
      Text("No recent conversions")
        .font(.subheadline)
        .foregroundColor(.secondary)
      Text("Pairs you convert will show up here")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
    .background(Color(uiColor: .secondarySystemGroupedBackground))
    .cornerRadius(12)
    .padding(.horizontal, 16)
  }

  // MARK: - Recent List

  private var recentList: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Recent Pairs")
          .font(.headline)
          .foregroundColor(.primary)
        Spacer()
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)

      VStack(spacing: 0) {
        ForEach(Array(appState.recentPairs.enumerated()), id: \.element) { idx, pair in
          if let from = Currency.byCode[pair.from], let to = Currency.byCode[pair.to] {
            RecentPairRow(pair: pair, from: from, to: to)
            if idx < appState.recentPairs.count - 1 {
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

// MARK: - Recent Pair Row

private struct RecentPairRow: View {
  @EnvironmentObject var appState: AppState
  let pair: CurrencyPair
  let from: Currency
  let to: Currency

  private var rate: Double {
    appState.conversionRate(from: from, to: to)
  }

  var body: some View {
    HStack(spacing: 12) {
      HStack(spacing: 2) {
        Text(from.flag).font(.system(size: 20))
        Text(to.flag).font(.system(size: 20))
      }
      .frame(width: 46)

      VStack(alignment: .leading, spacing: 2) {
        Text("\(from.code) → \(to.code)")
          .font(.system(size: 15, weight: .semibold))
        Text("\(from.name) → \(to.name)")
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(1)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 1) {
        Text(appState.formatAmount(rate, currency: to))
          .font(.system(size: 17, weight: .medium, design: .rounded))
          .foregroundColor(.primary)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
        Text("per 1 \(from.code)")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .contentShape(Rectangle())
    .onTapGesture {
      appState.sourceCurrency = from
      appState.targetCurrency = to
      appState.isSourceActive = true
      appState.recordCurrentPair()
      appState.saveSettings()
    }
    .onLongPressGesture {
      appState.removeRecentPair(pair)
    }
  }
}
