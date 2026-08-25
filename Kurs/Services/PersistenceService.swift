import Foundation

// MARK: - Persistence Service

final class PersistenceService {

  private let defaults = UserDefaults.standard

  // MARK: - Keys
  private enum Key {
    static let pinnedCurrencies = "kurs.pinnedCurrencies"
    static let recentPairs = "kurs.recentPairs"
    static let recentCurrencies = "kurs.recents"
    static let cachedRates = "kurs.rates"
    static let cacheDate = "kurs.cacheDate"
    static let rateSource = "kurs.rateSource"
    static let bankMarkup = "kurs.bankMarkup"
    static let offline = "kurs.offline"
    static let numberLocale = "kurs.numberLocale"
    static let provider = "kurs.provider"
    static let darkMode = "kurs.darkMode"
    static let darkModeSet = "kurs.darkModeSet"
    static let sourceCurrency = "kurs.sourceCurrency"
    static let targetCurrency = "kurs.targetCurrency"
  }

  // MARK: - Pinned Currencies

  func savePinned(_ codes: [String]) {
    defaults.set(codes, forKey: Key.pinnedCurrencies)
  }

  func loadPinned() -> [String]? {
    defaults.stringArray(forKey: Key.pinnedCurrencies)
  }

  // MARK: - Recent Pairs

  func saveRecentPairs(_ pairs: [CurrencyPair]) {
    guard let data = try? JSONEncoder().encode(pairs) else { return }
    defaults.set(data, forKey: Key.recentPairs)
  }

  func loadRecentPairs() -> [CurrencyPair] {
    guard let data = defaults.data(forKey: Key.recentPairs),
      let pairs = try? JSONDecoder().decode([CurrencyPair].self, from: data)
    else { return [] }
    return pairs
  }

  // MARK: - Recents

  func saveRecents(_ codes: [String]) {
    defaults.set(codes, forKey: Key.recentCurrencies)
  }

  func loadRecents() -> [String]? {
    defaults.stringArray(forKey: Key.recentCurrencies)
  }

  // MARK: - Rates Cache

  struct CachedRates {
    let rates: [String: Double]
    let date: Date
  }

  func saveRates(_ rates: [String: Double], date: Date) {
    if let data = try? JSONEncoder().encode(rates) {
      defaults.set(data, forKey: Key.cachedRates)
    }
    defaults.set(date, forKey: Key.cacheDate)
  }

  func loadCachedRates() -> CachedRates? {
    guard
      let data = defaults.data(forKey: Key.cachedRates),
      let date = defaults.object(forKey: Key.cacheDate) as? Date,
      let rates = try? JSONDecoder().decode([String: Double].self, from: data)
    else { return nil }
    return CachedRates(rates: rates, date: date)
  }

  // MARK: - Rate Source

  func saveRateSource(_ source: RateSource) {
    defaults.set(source.rawValue, forKey: Key.rateSource)
  }

  func loadRateSource() -> RateSource? {
    guard let raw = defaults.string(forKey: Key.rateSource) else { return nil }
    return RateSource(rawValue: raw)
  }

  // MARK: - Bank Markup

  func saveBankMarkup(_ markup: Double) {
    defaults.set(markup, forKey: Key.bankMarkup)
  }

  func loadBankMarkup() -> Double {
    let val = defaults.double(forKey: Key.bankMarkup)
    return val == 0 && !defaults.bool(forKey: "kurs.bankMarkupSet") ? 2.5 : val
  }

  // MARK: - Offline Mode

  func saveOffline(_ offline: Bool) {
    defaults.set(offline, forKey: Key.offline)
  }

  /// Absent key reads as `false`, which is the intended default (online).
  func loadOffline() -> Bool {
    defaults.bool(forKey: Key.offline)
  }

  // MARK: - Number Locale

  func saveNumberLocale(_ id: String) {
    defaults.set(id, forKey: Key.numberLocale)
  }

  func loadNumberLocale() -> String? {
    defaults.string(forKey: Key.numberLocale)
  }

  // MARK: - Data Sources

  func saveProvider(_ id: String) {
    defaults.set(id, forKey: Key.provider)
  }

  func loadProvider() -> String? {
    defaults.string(forKey: Key.provider)
  }

  // MARK: - Dark Mode

  func saveDarkMode(_ isDark: Bool?) {
    if let val = isDark {
      defaults.set(val, forKey: Key.darkMode)
      defaults.set(true, forKey: Key.darkModeSet)
    } else {
      defaults.removeObject(forKey: Key.darkMode)
      defaults.set(false, forKey: Key.darkModeSet)
    }
  }

  func loadDarkMode() -> Bool? {
    guard defaults.bool(forKey: Key.darkModeSet) else { return nil }
    return defaults.bool(forKey: Key.darkMode)
  }

  // MARK: - Currency Pair

  func saveSourceCurrency(_ code: String) {
    defaults.set(code, forKey: Key.sourceCurrency)
  }

  func loadSourceCurrency() -> String? {
    defaults.string(forKey: Key.sourceCurrency)
  }

  func saveTargetCurrency(_ code: String) {
    defaults.set(code, forKey: Key.targetCurrency)
  }

  func loadTargetCurrency() -> String? {
    defaults.string(forKey: Key.targetCurrency)
  }
}
