import Foundation

// MARK: - Rate Provider

/// Where every rate in the app comes from. One choice powers everything —
/// what differs between these is who publishes the numbers, how often, and
/// how many currencies they cover.
enum RateProvider: String, Codable, CaseIterable, Identifiable {
  case frankfurter
  case openERAPI
  case fawazCurrencyAPI

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .frankfurter: return "European Central Bank"
    case .openERAPI: return "Bank average"
    case .fawazCurrencyAPI: return "Widest coverage"
    }
  }

  /// Plain-language explanation of how this feed differs from the others.
  var summary: String {
    switch self {
    case .frankfurter:
      return
        "Europe's official rate. Published once each weekday afternoon, so it stays put during the day."
    case .openERAPI:
      return
        "Averaged across many banks and exchanges. Updated daily, and covers more currencies than the ECB."
    case .fawazCurrencyAPI:
      return "A free community feed with the longest currency list. Updated daily."
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

  /// Fetches USD-relative rates from the selected provider.
  func fetchRates(from provider: RateProvider) async throws -> [String: Double] {
    let rates = try await fetch(from: provider)
    if rates.isEmpty { throw URLError(.notConnectedToInternet) }
    return rates
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
