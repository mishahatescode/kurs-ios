import SwiftUI

// MARK: - Rate Source Sheet

struct RateSourceView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var localMarkup: Double
    @State private var localCustomRate: String
    @State private var localSource: RateSource

    @FocusState private var customRateFocused: Bool

    init(appState: AppState) {
        _localMarkup     = State(initialValue: appState.bankMarkup)
        _localCustomRate = State(initialValue: appState.customRate)
        _localSource     = State(initialValue: appState.rateSource)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Source Picker
                Section {
                    ForEach(RateSource.allCases, id: \.self) { source in
                        Button {
                            withAnimation { localSource = source }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: source.sfSymbol)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(source.displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text(source.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if localSource == source {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Rate Source")
                }

                // MARK: Bank Markup (Card/Bank only)
                if localSource == .card {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Markup")
                                    .font(.body)
                                Spacer()
                                Text(String(format: "%.1f%%", localMarkup))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.accentColor)
                                    .monospacedDigit()
                            }
                            Slider(value: $localMarkup, in: 0...12, step: 0.5)
                                .accentColor(.blue)
                        }
                        .padding(.vertical, 4)

                        // Quick presets
                        HStack(spacing: 8) {
                            ForEach([0.0, 1.5, 2.5, 3.5, 5.0], id: \.self) { preset in
                                Button {
                                    withAnimation { localMarkup = preset }
                                } label: {
                                    Text("\(preset == 0 ? "0" : String(format: "%.1f", preset))%")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            localMarkup == preset
                                                ? Color.accentColor
                                                : Color(uiColor: .systemGray5)
                                        )
                                        .foregroundColor(localMarkup == preset ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    } header: {
                        Text("Bank/Card Markup")
                    } footer: {
                        Text("Applied on top of live mid-market rate. A 2.5% markup is typical for many banks.")
                            .font(.caption)
                    }
                }

                // MARK: Custom Rate
                if localSource == .custom {
                    Section {
                        HStack(spacing: 8) {
                            Text("1 \(appState.sourceCurrency.code) =")
                                .foregroundColor(.secondary)
                                .font(.body)
                                .fixedSize()

                            TextField("Rate", text: $localCustomRate)
                                .keyboardType(.decimalPad)
                                .focused($customRateFocused)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 17, weight: .medium, design: .rounded))

                            Text(appState.targetCurrency.code)
                                .foregroundColor(.secondary)
                                .font(.body)
                                .fixedSize()
                        }
                    } header: {
                        Text("Custom Rate")
                    } footer: {
                        Text("Enter a fixed rate for \(appState.sourceCurrency.code) → \(appState.targetCurrency.code). Leave empty to use live rates.")
                            .font(.caption)
                    }
                }

                // MARK: Rate Info
                Section {
                    if let last = appState.lastUpdated {
                        HStack {
                            Text("Last updated")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(last, style: .relative)
                                .foregroundColor(.primary)
                                .font(.system(size: 14))
                        }
                    }

                    if appState.isOffline {
                        Label("Offline mode – using cached rates", systemImage: "wifi.slash")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                } header: {
                    Text("Status")
                }
            }
            .navigationTitle("Rate Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        appState.rateSource  = localSource
                        appState.bankMarkup  = localMarkup
                        appState.customRate  = localCustomRate
                        appState.saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onTapGesture {
                customRateFocused = false
            }
        }
    }
}
