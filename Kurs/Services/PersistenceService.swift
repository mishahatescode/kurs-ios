import Foundation

// MARK: - Persistence Service

final class PersistenceService {

  private let defaults = UserDefaults.standard

  // MARK: - Keys
  private enum Key {
    static let recentPairs = "kurs.recentPairs"
    static let recentCurrencies = "kurs.recents"
    static let cachedECBRates = "kurs.ecbRates"
    static let cachedLiveRates = "kurs.liveRates"
    static let cacheDate = "kurs.cacheDate"
    static let rateSource = "kurs.rateSource"
    static let bankMarkup = "kurs.bankMarkup"
    static let customRate = "kurs.customRate"
    static let darkMode = "kurs.darkMode"
    static let darkModeSet = "kurs.darkModeSet"
    static let sourceCurrency = "kurs.sourceCurrency"
    static let targetCurrency = "kurs.targetCurrency"
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
    let ecb: [String: Double]
    let live: [String: Double]
    let date: Date
  }

  func saveRates(ecb: [String: Double], live: [String: Double], date: Date) {
    if let ecbData = try? JSONEncoder().encode(ecb) {
      defaults.set(ecbData, forKey: Key.cachedECBRates)
    }
    if let liveData = try? JSONEncoder().encode(live) {
      defaults.set(liveData, forKey: Key.cachedLiveRates)
    }
    defaults.set(date, forKey: Key.cacheDate)
  }

  func loadCachedRates() -> CachedRates? {
    guard
      let ecbData = defaults.data(forKey: Key.cachedECBRates),
      let liveData = defaults.data(forKey: Key.cachedLiveRates),
      let date = defaults.object(forKey: Key.cacheDate) as? Date,
      let ecb = try? JSONDecoder().decode([String: Double].self, from: ecbData),
      let live = try? JSONDecoder().decode([String: Double].self, from: liveData)
    else { return nil }
    return CachedRates(ecb: ecb, live: live, date: date)
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

  // MARK: - Custom Rate

  func saveCustomRate(_ rate: String) {
    defaults.set(rate, forKey: Key.customRate)
  }

  func loadCustomRate() -> String {
    defaults.string(forKey: Key.customRate) ?? ""
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
