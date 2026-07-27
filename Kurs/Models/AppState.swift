import Foundation
import SwiftUI
import Combine

// MARK: - AppState

@MainActor
final class AppState: ObservableObject {

    // MARK: - Converter State
    @Published var sourceCurrency: Currency = Currency.byCode["USD"] ?? Currency.all[0]
    @Published var targetCurrency: Currency = Currency.byCode["EUR"] ?? Currency.all[1]
    @Published var amountString: String = "1"
    @Published var isSourceActive: Bool = true   // which side the keypad edits

    // MARK: - Currency Lists
    @Published var pinnedCurrencies: [String] = []   // codes
    @Published var recentCurrencies: [String] = []   // codes, max 8

    // MARK: - Rate Data
    @Published var ecbRates: [String: Double] = [:]
    @Published var liveRates: [String: Double] = [:]
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date? = nil
    @Published var loadError: String? = nil
    @Published var isOffline: Bool = false

    // MARK: - Rate Source & Settings
    @Published var rateSource: RateSource = .live
    @Published var bankMarkup: Double = 2.5      // percent
    @Published var customRate: String = ""        // raw input

    // MARK: - UI State
    @Published var isDarkMode: Bool? = nil        // nil = follow system
    @Published var showCurrencyPicker: Bool = false
    @Published var pickingForSource: Bool = true
    @Published var showRateSource: Bool = false
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
        switch rateSource {
        case .ecb:
            return ecbRates.isEmpty ? Currency.seedRates : mergedWithSeeds(ecbRates)
        case .live, .card:
            return liveRates.isEmpty ? (ecbRates.isEmpty ? Currency.seedRates : mergedWithSeeds(ecbRates))
                                     : mergedWithSeeds(liveRates)
        case .custom:
            return liveRates.isEmpty ? (ecbRates.isEmpty ? Currency.seedRates : mergedWithSeeds(ecbRates))
                                     : mergedWithSeeds(liveRates)
        }
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
        let toRate   = rates[to.code]   ?? Currency.seedRates[to.code]   ?? 1.0

        guard fromRate > 0 else { return 1.0 }
        let base = toRate / fromRate

        switch rateSource {
        case .ecb, .live:
            return base
        case .card:
            return base * (1 + bankMarkup / 100)
        case .custom:
            let cv = Double(customRate.replacingOccurrences(of: ",", with: ".")) ?? 0
            if cv > 0 {
                // custom rate is interpreted as: 1 unit of sourceCurrency = cv units of targetCurrency
                // Only apply when converting exactly the active pair; otherwise fall back
                if from.code == sourceCurrency.code && to.code == targetCurrency.code {
                    return cv
                } else if from.code == targetCurrency.code && to.code == sourceCurrency.code {
                    return 1.0 / cv
                }
            }
            return base
        }
    }

    var convertedAmount: Double {
        amount * conversionRate(from: sourceCurrency, to: targetCurrency)
    }

    func pinnedAmount(for currencyCode: String) -> Double {
        guard let cur = Currency.byCode[currencyCode] else { return 0 }
        let activeCurrency = isSourceActive ? sourceCurrency : targetCurrency
        let activeAmount = isSourceActive ? amount : convertedAmount
        return activeAmount * conversionRate(from: activeCurrency, to: cur)
    }

    var rateInfoString: String {
        let rate = conversionRate(from: sourceCurrency, to: targetCurrency)
        let formattedRate = formatAmount(rate, currency: targetCurrency)
        let sourceLabel = rateSource == .ecb ? "ECB" :
                          rateSource == .live ? "Live" :
                          rateSource == .card ? "Bank" : "Custom"
        return "1 \(sourceCurrency.code) = \(formattedRate) \(targetCurrency.code) · \(sourceLabel)"
    }

    // MARK: - Formatting

    func formatAmount(_ value: Double, currency: Currency) -> String {
        if value.isNaN || value.isInfinite { return "0" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = currency.decimalPlaces
        formatter.maximumFractionDigits = currency.decimalPlaces
        formatter.usesGroupingSeparator = true
        formatter.locale = Locale.current
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
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
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
                let decimalsEntered = amountString.distance(from: amountString.index(after: sepIdx),
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
        sourceCurrency = oldTarget
        targetCurrency = oldSource
        // Recalculate: keep the active side value, update the other
        isSourceActive = true
    }

    // MARK: - Rate Refresh

    func refreshRates() async {
        guard !isOffline else { return }
        isLoading = true
        loadError = nil

        do {
            let (ecb, live) = try await exchangeService.fetchBothRates()
            ecbRates = ecb
            liveRates = live
            lastUpdated = Date()
            loadError = nil
            persistence.saveRates(ecb: ecb, live: live, date: lastUpdated!)
        } catch {
            // Try to load cached
            if let cached = persistence.loadCachedRates() {
                ecbRates = cached.ecb
                liveRates = cached.live
                lastUpdated = cached.date
                loadError = "Offline – using cached rates"
            } else {
                loadError = "Could not load rates – using built-in fallback"
            }
        }

        isLoading = false
    }

    func refreshIfStale() async {
        guard let last = lastUpdated else {
            await refreshRates()
            return
        }
        if Date().timeIntervalSince(last) > 15 * 60 {
            await refreshRates()
        }
    }

    // MARK: - Pinned Currencies

    func togglePin(_ code: String) {
        if pinnedCurrencies.contains(code) {
            pinnedCurrencies.removeAll { $0 == code }
            showToast("\(code) unpinned")
        } else {
            pinnedCurrencies.append(code)
            showToast("\(code) pinned")
        }
        persistence.savePinned(pinnedCurrencies)
    }

    func isPinned(_ code: String) -> Bool {
        pinnedCurrencies.contains(code)
    }

    func movePinned(from source: IndexSet, to destination: Int) {
        pinnedCurrencies.move(fromOffsets: source, toOffset: destination)
        persistence.savePinned(pinnedCurrencies)
    }

    func removePinned(at offsets: IndexSet) {
        pinnedCurrencies.remove(atOffsets: offsets)
        persistence.savePinned(pinnedCurrencies)
    }

    // MARK: - Recent Currencies

    func recordRecent(_ code: String) {
        recentCurrencies.removeAll { $0 == code }
        recentCurrencies.insert(code, at: 0)
        if recentCurrencies.count > 8 { recentCurrencies = Array(recentCurrencies.prefix(8)) }
        persistence.saveRecents(recentCurrencies)
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
        if let pinned = p.loadPinned() { pinnedCurrencies = pinned }
        if let recents = p.loadRecents() { recentCurrencies = recents }
        if let cached = p.loadCachedRates() {
            ecbRates = cached.ecb
            liveRates = cached.live
            lastUpdated = cached.date
        }
        if let src = p.loadRateSource() { rateSource = src }
        bankMarkup = p.loadBankMarkup()
        customRate = p.loadCustomRate()
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
        persistence.saveCustomRate(customRate)
        persistence.saveDarkMode(isDarkMode)
        persistence.saveSourceCurrency(sourceCurrency.code)
        persistence.saveTargetCurrency(targetCurrency.code)
    }
}
