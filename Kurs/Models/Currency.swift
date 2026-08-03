import Foundation

// MARK: - Currency Model

struct Currency: Identifiable, Codable, Equatable, Hashable {
  let code: String
  let name: String
  let flag: String
  let decimalPlaces: Int

  var id: String { code }

  func hash(into hasher: inout Hasher) {
    hasher.combine(code)
  }

  static func == (lhs: Currency, rhs: Currency) -> Bool {
    lhs.code == rhs.code
  }
}

// MARK: - Rate Source

enum RateSource: String, Codable, CaseIterable {
  case ecb = "ECB"
  case live = "Live"
  case card = "Card/Bank"
  case custom = "Custom"

  var displayName: String {
    switch self {
    case .ecb: return "ECB"
    case .live: return "Mid-market"
    case .card: return "Card/Bank"
    case .custom: return "Custom"
    }
  }

  var description: String {
    switch self {
    case .ecb: return "Europe's official rate — set once a day, not every second"
    case .live: return "The real rate right now — no extra fees added"
    case .card: return "Like paying with a card abroad — a small fee added on top"
    case .custom: return "A number you type in yourself, like a rate someone told you"
    }
  }

  var sfSymbol: String {
    switch self {
    case .ecb: return "building.columns"
    case .live: return "chart.line.uptrend.xyaxis"
    case .card: return "creditcard"
    case .custom: return "pencil"
    }
  }
}

// MARK: - All Currencies

extension Currency {
  static let all: [Currency] = [
    Currency(code: "USD", name: "US Dollar", flag: "🇺🇸", decimalPlaces: 2),
    Currency(code: "EUR", name: "Euro", flag: "🇪🇺", decimalPlaces: 2),
    Currency(code: "GBP", name: "British Pound", flag: "🇬🇧", decimalPlaces: 2),
    Currency(code: "JPY", name: "Japanese Yen", flag: "🇯🇵", decimalPlaces: 0),
    Currency(code: "CAD", name: "Canadian Dollar", flag: "🇨🇦", decimalPlaces: 2),
    Currency(code: "AUD", name: "Australian Dollar", flag: "🇦🇺", decimalPlaces: 2),
    Currency(code: "CHF", name: "Swiss Franc", flag: "🇨🇭", decimalPlaces: 2),
    Currency(code: "CNY", name: "Chinese Yuan", flag: "🇨🇳", decimalPlaces: 2),
    Currency(code: "HKD", name: "Hong Kong Dollar", flag: "🇭🇰", decimalPlaces: 2),
    Currency(code: "SGD", name: "Singapore Dollar", flag: "🇸🇬", decimalPlaces: 2),
    Currency(code: "SEK", name: "Swedish Krona", flag: "🇸🇪", decimalPlaces: 2),
    Currency(code: "NOK", name: "Norwegian Krone", flag: "🇳🇴", decimalPlaces: 2),
    Currency(code: "DKK", name: "Danish Krone", flag: "🇩🇰", decimalPlaces: 2),
    Currency(code: "NZD", name: "New Zealand Dollar", flag: "🇳🇿", decimalPlaces: 2),
    Currency(code: "MXN", name: "Mexican Peso", flag: "🇲🇽", decimalPlaces: 2),
    Currency(code: "BRL", name: "Brazilian Real", flag: "🇧🇷", decimalPlaces: 2),
    Currency(code: "INR", name: "Indian Rupee", flag: "🇮🇳", decimalPlaces: 2),
    Currency(code: "KRW", name: "South Korean Won", flag: "🇰🇷", decimalPlaces: 0),
    Currency(code: "TRY", name: "Turkish Lira", flag: "🇹🇷", decimalPlaces: 2),
    Currency(code: "ZAR", name: "South African Rand", flag: "🇿🇦", decimalPlaces: 2),
    Currency(code: "RUB", name: "Russian Ruble", flag: "🇷🇺", decimalPlaces: 2),
    Currency(code: "PLN", name: "Polish Zloty", flag: "🇵🇱", decimalPlaces: 2),
    Currency(code: "THB", name: "Thai Baht", flag: "🇹🇭", decimalPlaces: 2),
    Currency(code: "IDR", name: "Indonesian Rupiah", flag: "🇮🇩", decimalPlaces: 0),
    Currency(code: "HUF", name: "Hungarian Forint", flag: "🇭🇺", decimalPlaces: 2),
    Currency(code: "CZK", name: "Czech Koruna", flag: "🇨🇿", decimalPlaces: 2),
    Currency(code: "ILS", name: "Israeli Shekel", flag: "🇮🇱", decimalPlaces: 2),
    Currency(code: "AED", name: "UAE Dirham", flag: "🇦🇪", decimalPlaces: 2),
    Currency(code: "SAR", name: "Saudi Riyal", flag: "🇸🇦", decimalPlaces: 2),
    Currency(code: "MYR", name: "Malaysian Ringgit", flag: "🇲🇾", decimalPlaces: 2),
    Currency(code: "PHP", name: "Philippine Peso", flag: "🇵🇭", decimalPlaces: 2),
    Currency(code: "VND", name: "Vietnamese Dong", flag: "🇻🇳", decimalPlaces: 0),
    Currency(code: "PKR", name: "Pakistani Rupee", flag: "🇵🇰", decimalPlaces: 2),
    Currency(code: "BDT", name: "Bangladeshi Taka", flag: "🇧🇩", decimalPlaces: 2),
    Currency(code: "EGP", name: "Egyptian Pound", flag: "🇪🇬", decimalPlaces: 2),
    Currency(code: "NGN", name: "Nigerian Naira", flag: "🇳🇬", decimalPlaces: 2),
    Currency(code: "KES", name: "Kenyan Shilling", flag: "🇰🇪", decimalPlaces: 2),
    Currency(code: "GHS", name: "Ghanaian Cedi", flag: "🇬🇭", decimalPlaces: 2),
    Currency(code: "UAH", name: "Ukrainian Hryvnia", flag: "🇺🇦", decimalPlaces: 2),
    Currency(code: "RON", name: "Romanian Leu", flag: "🇷🇴", decimalPlaces: 2),
    Currency(code: "BGN", name: "Bulgarian Lev", flag: "🇧🇬", decimalPlaces: 2),
    Currency(code: "HRK", name: "Croatian Kuna", flag: "🇭🇷", decimalPlaces: 2),
    Currency(code: "ISK", name: "Icelandic Krona", flag: "🇮🇸", decimalPlaces: 0),
    Currency(code: "KWD", name: "Kuwaiti Dinar", flag: "🇰🇼", decimalPlaces: 3),
    Currency(code: "BHD", name: "Bahraini Dinar", flag: "🇧🇭", decimalPlaces: 3),
    Currency(code: "OMR", name: "Omani Rial", flag: "🇴🇲", decimalPlaces: 3),
    Currency(code: "JOD", name: "Jordanian Dinar", flag: "🇯🇴", decimalPlaces: 3),
    Currency(code: "QAR", name: "Qatari Riyal", flag: "🇶🇦", decimalPlaces: 2),
    Currency(code: "CLP", name: "Chilean Peso", flag: "🇨🇱", decimalPlaces: 0),
    Currency(code: "COP", name: "Colombian Peso", flag: "🇨🇴", decimalPlaces: 0),
  ]

  static let byCode: [String: Currency] = Dictionary(
    uniqueKeysWithValues: all.map { ($0.code, $0) })

  // Seed rates (USD-relative, 1 USD = X currency)
  static let seedRates: [String: Double] = [
    "USD": 1.0,
    "EUR": 0.9234,
    "GBP": 0.7867,
    "JPY": 152.40,
    "CAD": 1.3625,
    "AUD": 1.5312,
    "CHF": 0.8967,
    "CNY": 7.2456,
    "HKD": 7.8234,
    "SGD": 1.3445,
    "SEK": 10.4231,
    "NOK": 10.5678,
    "DKK": 6.8901,
    "NZD": 1.6234,
    "MXN": 17.1234,
    "BRL": 4.9678,
    "INR": 83.1234,
    "KRW": 1326.5,
    "TRY": 30.8901,
    "ZAR": 18.7234,
    "RUB": 91.2345,
    "PLN": 3.9567,
    "THB": 35.2345,
    "IDR": 15678.0,
    "HUF": 357.89,
    "CZK": 22.9012,
    "ILS": 3.7234,
    "AED": 3.6725,
    "SAR": 3.7500,
    "MYR": 4.7123,
    "PHP": 56.3456,
    "VND": 24567.0,
    "PKR": 278.9012,
    "BDT": 110.2345,
    "EGP": 30.9012,
    "NGN": 1456.789,
    "KES": 129.3456,
    "GHS": 12.3456,
    "UAH": 38.5678,
    "RON": 4.6789,
    "BGN": 1.8056,
    "HRK": 6.7234,
    "ISK": 138.0,
    "KWD": 0.3070,
    "BHD": 0.3770,
    "OMR": 0.3845,
    "JOD": 0.7090,
    "QAR": 3.6400,
    "CLP": 897.0,
    "COP": 3967.0,
  ]
}
