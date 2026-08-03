import Foundation

// MARK: - Rate Provider

/// A pluggable rates feed. Both the "ECB Source" and "Mid-market Source"
/// slots in Settings can be pointed at any of these — they're just
/// interchangeable "give me a USD-based rates dictionary" backends.
enum RateProvider: String, Codable, CaseIterable, Identifiable {
  case frankfurter
  case openERAPI
  case fawazCurrencyAPI

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .frankfurter: return "Frankfurter"
    case .openERAPI: return "ExchangeRate-API"
    case .fawazCurrencyAPI: return "Currency-API"
    }
  }

  var host: String {
    switch self {
    case .frankfurter: return "api.frankfurter.app"
    case .openERAPI: return "open.er-api.com"
    case .fawazCurrencyAPI: return "cdn.jsdelivr.net"
    }
  }
}

// MARK: - Exchange Rate Service (Actor for thread safety)

actor ExchangeRateService {

  private let session: URLSession

  init() {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 4.5
    config.timeoutIntervalForResource = 6.0
    self.session = URLSession(configuration: config)
  }

  // MARK: - Public API

  /// Fetches the ECB-slot and Mid-market-slot rates concurrently, using
  /// whichever provider each slot is currently configured to use.
  /// Returns (ecbRates, midMarketRates), both USD-relative dictionaries.
  func fetchBothRates(
    ecbProvider: RateProvider,
    midMarketProvider: RateProvider
  ) async throws -> ([String: Double], [String: Double]) {
    async let ecbTask = fetch(from: ecbProvider)
    async let midTask = fetch(from: midMarketProvider)

    var ecb: [String: Double] = [:]
    var mid: [String: Double] = [:]

    do { ecb = try await ecbTask } catch { ecb = [:] }
    do { mid = try await midTask } catch { mid = [:] }

    // If one completely failed, use the other for both
    if ecb.isEmpty && !mid.isEmpty { ecb = mid }
    if mid.isEmpty && !ecb.isEmpty { mid = ecb }

    // If both failed, throw so caller knows to fall back
    if ecb.isEmpty && mid.isEmpty {
      throw URLError(.notConnectedToInternet)
    }

    return (ecb, mid)
  }

  private func fetch(from provider: RateProvider) async throws -> [String: Double] {
    switch provider {
    case .frankfurter: return try await fetchFrankfurter()
    case .openERAPI: return try await fetchOpenER()
    case .fawazCurrencyAPI: return try await fetchFawazCurrencyAPI()
    }
  }

  // MARK: - Frankfurter (ECB reference rates)

  private func fetchFrankfurter() async throws -> [String: Double] {
    let url = URL(string: "https://api.frankfurter.app/latest?from=USD")!
    let (data, response) = try await session.data(from: url)

    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }

    let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
    var rates = decoded.rates
    rates["USD"] = 1.0
    return rates
  }

  // MARK: - open.er-api.com (mid-market aggregate)

  private func fetchOpenER() async throws -> [String: Double] {
    let url = URL(string: "https://open.er-api.com/v6/latest/USD")!
    let (data, response) = try await session.data(from: url)

    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }

    let decoded = try JSONDecoder().decode(OpenERResponse.self, from: data)
    guard decoded.result == "success" else { throw URLError(.badServerResponse) }
    return decoded.rates
  }

  // MARK: - Fawaz Ahmed's currency-api (community, CDN-hosted, no key)

  private func fetchFawazCurrencyAPI() async throws -> [String: Double] {
    let url = URL(
      string: "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json"
    )!
    let (data, response) = try await session.data(from: url)

    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }

    let decoded = try JSONDecoder().decode(FawazResponse.self, from: data)
    var rates: [String: Double] = [:]
    for (code, value) in decoded.usd { rates[code.uppercased()] = value }
    rates["USD"] = 1.0
    return rates
  }

  // MARK: - Response Models

  private struct FrankfurterResponse: Decodable {
    let amount: Double
    let base: String
    let date: String
    let rates: [String: Double]
  }

  private struct OpenERResponse: Decodable {
    let result: String
    let base_code: String
    let rates: [String: Double]
  }

  private struct FawazResponse: Decodable {
    let date: String
    let usd: [String: Double]
  }
}
