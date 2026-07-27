import Foundation

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

  /// Fetches ECB and Live rates concurrently.
  /// Returns (ecbRates, liveRates) both as USD-relative dictionaries.
  func fetchBothRates() async throws -> ([String: Double], [String: Double]) {
    async let ecbTask = fetchECBRates()
    async let liveTask = fetchLiveRates()

    var ecb: [String: Double] = [:]
    var live: [String: Double] = [:]

    do { ecb = try await ecbTask } catch { ecb = [:] }
    do { live = try await liveTask } catch { live = [:] }

    // If one completely failed, use the other for both
    if ecb.isEmpty && !live.isEmpty { ecb = live }
    if live.isEmpty && !ecb.isEmpty { live = ecb }

    // If both failed, throw so caller knows to fall back
    if ecb.isEmpty && live.isEmpty {
      throw URLError(.notConnectedToInternet)
    }

    return (ecb, live)
  }

  // MARK: - ECB via frankfurter.app

  private func fetchECBRates() async throws -> [String: Double] {
    let url = URL(string: "https://api.frankfurter.app/latest?from=USD")!
    let (data, response) = try await session.data(from: url)

    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }

    let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
    var rates = decoded.rates
    rates["USD"] = 1.0
    // Convert to USD-relative (API already gives USD-based rates)
    return rates
  }

  // MARK: - Live via open.er-api.com

  private func fetchLiveRates() async throws -> [String: Double] {
    let url = URL(string: "https://open.er-api.com/v6/latest/USD")!
    let (data, response) = try await session.data(from: url)

    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }

    let decoded = try JSONDecoder().decode(OpenERResponse.self, from: data)
    guard decoded.result == "success" else { throw URLError(.badServerResponse) }
    return decoded.rates
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
}
