import Combine
import Foundation
import SwiftUI

// MARK: - Currency Pair

struct CurrencyPair: Codable, Hashable {
  let from: String
  let to: String
}

// MARK: - Number Locale

/// The number-formatting locale (grouping/decimal separators) is chosen
/// independently of the device locale, matching the original prototype.
struct NumberLocaleOption: Identifiable, Equatable {
  let id: String
  let name: String

  static let all: [NumberLocaleOption] = [
    NumberLocaleOption(id: "en-US", name: "United States"),
    NumberLocaleOption(id: "de-DE", name: "Germany"),
    NumberLocaleOption(id: "fr-FR", name: "France"),
    NumberLocaleOption(id: "en-IN", name: "India"),
  ]
}

// MARK: - AppState

@MainActor
final class AppState: ObservableObject {

  // MARK: - Converter State
  @Published var sourceCurrency: Currency = Currency.byCode["USD"] ?? Currency.all[0]
  @Published var targetCurrency: Currency = Currency.byCode["EUR"] ?? Currency.all[1]
  @Published var amountString: String = "1"
  @Published var isSourceActive: Bool = true  // which side the keypad edits

  // MARK: - Currency Lists
  @Published var pinnedCurrencies: [String] = []  // codes, always shown first in the picker
  @Published var recentPairs: [CurrencyPair] = []  // most recent first, max 10
  @Published var recentCurrencies: [String] = []  // codes, max 8 — used by the currency picker's "Recent" section

  // MARK: - Rate Data
  @Published var rates: [String: Double] = [:]
  @Published var isLoading: Bool = false
  @Published var lastUpdated: Date? = nil
  @Published var loadError: String? = nil
  @Published var isOffline: Bool = false

  // MARK: - Rate Source & Settings
  @Published var rateSource: RateSource = .market
  @Published var bankMarkup: Double = 2.5  // percent
  @Published var numberLocaleID: String = "en-US"

  var numberLocale: Locale { Locale(identifier: numberLocaleID) }

  // MARK: - Data Sources

  /// One feed powers every rate in the app.
  @Published var providerID: String = RateProvider.openERAPI.rawValue

  var provider: RateProvider { RateProvider(rawValue: providerID) ?? .openERAPI }

  /// How many of the app's currencies actually came back in the last fetch —
  /// real, source-dependent coverage rather than the app's fixed total (the
  /// ECB, for instance, covers far fewer currencies than a broad aggregator).
  var supportedCurrencyCount: Int? {
    guard !rates.isEmpty else { return nil }
    return Currency.all.filter { rates[$0.code] != nil }.count
  }

  // MARK: - UI State
  @Published var isDarkMode: Bool? = nil  // nil = follow system
  @Published var showCurrencyPicker: Bool = false
  @Published var pickingForSource: Bool = true
  @Published var showSettings: Bool = false
  @Published var toastMessage: String? = nil

  private var toastTask: Task<Void, Never>? = nil

  // MARK: - Services
  private let exchangeService = ExchangeRateService()
  private let persistence = PersistenceService()

  // MARK: - Init

  init() {
    loadPersistedState()
    Task { await refreshRates() }
  }

  // MARK: - Computed Properties

  var amount: Double {
    let normalised = amountString.replacingOccurrences(of: ",", with: ".")
    return Double(normalised) ?? 0
  }

  var effectiveRates: [String: Double] {
    rates.isEmpty ? Currency.seedRates : mergedWithSeeds(rates)
  }

  private func mergedWithSeeds(_ rates: [String: Double]) -> [String: Double] {
    var merged = Currency.seedRates
    for (k, v) in rates { merged[k] = v }
    return merged
  }

  /// Returns conversion rate from → to, applying markup/custom as needed
  func conversionRate(from: Currency, to: Currency) -> Double {
    if from.code == to.code { return 1.0 }

    let rates = effectiveRates
    let fromRate = rates[from.code] ?? Currency.seedRates[from.code] ?? 1.0
    let toRate = rates[to.code] ?? Currency.seedRates[to.code] ?? 1.0

    guard fromRate > 0 else { return 1.0 }
    let base = toRate / fromRate

    switch rateSource {
    case .market:
      return base
    case .card:
      // The markup must cost the customer money regardless of which way
      // they convert — applying `base * (1 + markup)` in both directions
      // independently made a round trip *profitable* (base is an exact
      // reciprocal, so the two markups compounded into a net gain).
      // A flat `(1 - markup)` penalty on the mid-rate conversion means
      // every conversion — either direction — comes out behind the mid
      // rate, so a round trip loses ~2×markup instead of gaining any.
      return base * (1 - bankMarkup / 100)
    }
  }

  var convertedAmount: Double {
    amount * conversionRate(from: sourceCurrency, to: targetCurrency)
  }

  var rateInfoString: String {
    let rate = conversionRate(from: sourceCurrency, to: targetCurrency)
    let formattedRate = formatAmount(rate, currency: targetCurrency)
    let sourceLabel: String
    switch rateSource {
    case .market: sourceLabel = provider.displayName
    case .card: sourceLabel = "Card or bank"
    }
    return "1 \(sourceCurrency.code) = \(formattedRate) \(targetCurrency.code) · \(sourceLabel)"
  }

  /// "just now" / "3 min ago" / "2 hours ago", relative to `lastUpdated`.
  func updatedAgoText(now: Date = Date()) -> String {
    guard let last = lastUpdated else { return "just now" }
    let mins = Int(now.timeIntervalSince(last) / 60)
    if mins < 1 { return "just now" }
    if mins == 1 { return "1 min ago" }
    if mins < 60 { return "\(mins) min ago" }
    let hours = Int((Double(mins) / 60).rounded())
    return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
  }

  // MARK: - Formatting

  func formatAmount(_ value: Double, currency: Currency) -> String {
    if value.isNaN || value.isInfinite { return "0" }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = currency.decimalPlaces
    formatter.maximumFractionDigits = currency.decimalPlaces
    formatter.usesGroupingSeparator = true
    formatter.locale = numberLocale
    return formatter.string(from: NSNumber(value: value)) ?? "0"
  }

  func formatAmountRaw(_ value: Double, currency: Currency) -> String {
    if value.isNaN || value.isInfinite { return "0" }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = currency.decimalPlaces
    formatter.usesGroupingSeparator = false
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: NSNumber(value: value)) ?? "0"
  }

  // MARK: - Keypad Input

  func keypadTap(_ key: String) {
    let decimalSeparator = numberLocale.decimalSeparator ?? "."
    let maxDec = isSourceActive ? sourceCurrency.decimalPlaces : targetCurrency.decimalPlaces

    switch key {
    case "⌫":
      if amountString.count > 1 {
        amountString.removeLast()
      } else {
        amountString = "0"
      }
    case ".", ",":
      if maxDec == 0 { return }
      if !amountString.contains(".") && !amountString.contains(",") {
        amountString += decimalSeparator
      }
    default:
      // Enforce decimal place limit
      if let sepIdx = amountString.firstIndex(of: Character(decimalSeparator)) {
        let decimalsEntered = amountString.distance(
          from: amountString.index(after: sepIdx),
          to: amountString.endIndex)
        if decimalsEntered >= maxDec { return }
      }
      // Remove leading zero unless adding decimal
      if amountString == "0" {
        amountString = key
      } else {
        amountString += key
      }
    }

    // Sync to opposite side if inactive side was last edited
    if !isSourceActive {
      // We're editing the target; convert back to source
      let targetAmt = Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0
      let rate = conversionRate(from: sourceCurrency, to: targetCurrency)
      if rate > 0 {
        let sourceAmt = targetAmt / rate
        amountString = formatAmountRaw(sourceAmt, currency: sourceCurrency)
        isSourceActive = true
      }
    }
  }

  // MARK: - Swap

  func swapCurrencies() {
    let oldSource = sourceCurrency
    let oldTarget = targetCurrency
    // Capture the amount currently shown on the target side *before* the
    // currencies flip — after the swap it becomes the new source amount,
    // so the two rows trade places together with their values instead of
    // the typed digits being reinterpreted under the new currency.
    let newSourceAmount = convertedAmount

    sourceCurrency = oldTarget
    targetCurrency = oldSource
    amountString = formatAmountRaw(newSourceAmount, currency: sourceCurrency)
    isSourceActive = true
    recordCurrentPair()
  }

  /// Clears the amount currently being edited back to zero (long-press ⌫).
  func clearAmount() {
    amountString = "0"
  }

  // MARK: - Rate Refresh

  func refreshRates() async {
    guard !isOffline else {
      // The "Offline Mode" toggle simulates no connectivity without ever
      // hitting the network — still surface the same stale-rates signal a
      // real network failure would, so the UI has one code path to render.
      loadError = "Offline — showing cached rates"
      return
    }
    isLoading = true
    loadError = nil

    do {
      let fetched = try await exchangeService.fetchRates(from: provider)
      rates = fetched
      lastUpdated = Date()
      loadError = nil
      persistence.saveRates(fetched, date: lastUpdated!)
    } catch {
      // Try to load cached
      if let cached = persistence.loadCachedRates() {
        rates = cached.rates
        lastUpdated = cached.date
        loadError = "No connection — showing cached rates"
      } else {
        loadError = "No connection — using built-in fallback rates"
      }
    }

    isLoading = false
  }

  // MARK: - Offline Mode

  /// Flipping the switch has to change what's on screen straight away. The
  /// offline/stale signal is driven by `loadError`, which otherwise wouldn't
  /// be set until the next refresh attempt — so the toggle looked inert until
  /// you happened to pull-to-refresh.
  func setOffline(_ offline: Bool) {
    isOffline = offline
    persistence.saveOffline(offline)
    if offline {
      isLoading = false
      loadError = "Offline — showing cached rates"
    } else {
      loadError = nil
      Task { await refreshRates() }
    }
  }

  // MARK: - Pinned Currencies

  func isPinned(_ code: String) -> Bool { pinnedCurrencies.contains(code) }

  func togglePin(_ code: String) {
    if pinnedCurrencies.contains(code) {
      pinnedCurrencies.removeAll { $0 == code }
    } else {
      pinnedCurrencies.append(code)
    }
    persistence.savePinned(pinnedCurrencies)
  }

  func clearPinnedCurrencies() {
    pinnedCurrencies = []
    persistence.savePinned([])
  }

  // MARK: - Recent Pairs

  /// Records the currently active source→target pair at the front of the
  /// recent-pairs list (moving it there if it's already present), capped at 10.
  func recordCurrentPair() {
    // A same-currency pair is always 1:1 and tells the user nothing — it can
    // happen by picking the currency that's already on the other side.
    guard sourceCurrency.code != targetCurrency.code else { return }
    let pair = CurrencyPair(from: sourceCurrency.code, to: targetCurrency.code)
    recentPairs.removeAll { $0 == pair }
    recentPairs.insert(pair, at: 0)
    if recentPairs.count > 10 { recentPairs = Array(recentPairs.prefix(10)) }
    persistence.saveRecentPairs(recentPairs)
  }

  func removeRecentPair(_ pair: CurrencyPair) {
    recentPairs.removeAll { $0 == pair }
    persistence.saveRecentPairs(recentPairs)
  }

  func clearRecentPairs() {
    recentPairs = []
    persistence.saveRecentPairs([])
  }

  // MARK: - Recent Currencies

  func recordRecent(_ code: String) {
    recentCurrencies.removeAll { $0 == code }
    recentCurrencies.insert(code, at: 0)
    if recentCurrencies.count > 8 { recentCurrencies = Array(recentCurrencies.prefix(8)) }
    persistence.saveRecents(recentCurrencies)
  }

  func clearRecentCurrencies() {
    recentCurrencies = []
    persistence.saveRecents([])
  }

  // MARK: - Toast

  func showToast(_ message: String) {
    toastTask?.cancel()
    toastMessage = message
    toastTask = Task {
      try? await Task.sleep(nanoseconds: 2_500_000_000)
      if !Task.isCancelled {
        toastMessage = nil
      }
    }
  }

  // MARK: - Persistence Load

  private func loadPersistedState() {
    let p = persistence
    pinnedCurrencies = p.loadPinned() ?? []
    recentPairs = p.loadRecentPairs()
    if let recents = p.loadRecents() { recentCurrencies = recents }
    if let cached = p.loadCachedRates() {
      rates = cached.rates
      lastUpdated = cached.date
    }
    if let src = p.loadRateSource() { rateSource = src }
    bankMarkup = p.loadBankMarkup()
    isOffline = p.loadOffline()
    if let loc = p.loadNumberLocale() { numberLocaleID = loc }
    if let pID = p.loadProvider() { providerID = pID }
    isDarkMode = p.loadDarkMode()
    if let srcCode = p.loadSourceCurrency(), let cur = Currency.byCode[srcCode] {
      sourceCurrency = cur
    }
    if let tgtCode = p.loadTargetCurrency(), let cur = Currency.byCode[tgtCode] {
      targetCurrency = cur
    }
  }

  func saveSettings() {
    persistence.saveRateSource(rateSource)
    persistence.saveBankMarkup(bankMarkup)
    persistence.saveOffline(isOffline)
    persistence.saveNumberLocale(numberLocaleID)
    persistence.saveProvider(providerID)
    persistence.saveDarkMode(isDarkMode)
    persistence.saveSourceCurrency(sourceCurrency.code)
    persistence.saveTargetCurrency(targetCurrency.code)
  }
}
