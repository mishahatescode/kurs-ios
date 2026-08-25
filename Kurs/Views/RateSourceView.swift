import SwiftUI

// MARK: - Rate Source Sheet

struct RateSourceView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @State private var localMarkup: Double
  @State private var localSource: RateSource
  @State private var showDataSources = false

  init(appState: AppState) {
    _localMarkup = State(initialValue: appState.bankMarkup)
    _localSource = State(initialValue: appState.rateSource)
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

                // Always laid out, only faded in/out — a conditional checkmark
                // changes the row's width and shoves the text sideways as the
                // selection moves.
                Image(systemName: "checkmark")
                  .foregroundColor(.accentColor)
                  .font(.system(size: 14, weight: .semibold))
                  .opacity(localSource == source ? 1 : 0)
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
            Text("Taken off the rate from your data source. 2.5% is typical for many banks.")
              .font(.caption)
          }
        }

        // MARK: Data Sources
        Section {
          Button {
            showDataSources = true
          } label: {
            HStack {
              Text("Data Source")
                .foregroundColor(.primary)
              Spacer()
              Text(appState.provider.displayName)
                .foregroundColor(.secondary)
                .lineLimit(1)
              Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        } footer: {
          Text("Where every rate in the app comes from.")
            .font(.caption)
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
            appState.rateSource = localSource
            appState.bankMarkup = localMarkup
                    appState.saveSettings()
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
      .sheet(isPresented: $showDataSources) {
        DataSourcesView(appState: appState)
          .environmentObject(appState)
          .kursAppearance(appState.isDarkMode)
      }
    }
  }
}
