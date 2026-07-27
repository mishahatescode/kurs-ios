import SwiftUI

// MARK: - Numeric Keypad

struct NumericKeypad: View {
    @EnvironmentObject var appState: AppState

    private let activeCurrency: Currency
    private var maxDecimals: Int { activeCurrency.decimalPlaces }

    private let rows: [[String]] = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        [".", "0", "⌫"],
    ]

    init(activeCurrency: Currency) {
        self.activeCurrency = activeCurrency
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 2) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(row, id: \.self) { key in
                            KeypadButton(
                                key: key,
                                isDisabled: key == "." && maxDecimals == 0
                            ) {
                                appState.keypadTap(key)
                                appState.saveSettings()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

// MARK: - Keypad Button

private struct KeypadButton: View {
    let key: String
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            let impactMed = UIImpactFeedbackGenerator(style: .light)
            impactMed.impactOccurred()
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(buttonBackground)
                    .shadow(color: .black.opacity(0.1), radius: 0.5, x: 0, y: 1)

                if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(isDisabled ? .secondary.opacity(0.4) : .primary)
                } else {
                    Text(localizedKey)
                        .font(.system(size: 24, weight: .regular, design: .rounded))
                        .foregroundColor(isDisabled ? .secondary.opacity(0.4) : .primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: keyHeight)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isDisabled)
    }

    private var localizedKey: String {
        if key == "." {
            return Locale.current.decimalSeparator ?? "."
        }
        return key
    }

    private var buttonBackground: Color {
        if key == "⌫" {
            return Color(uiColor: .systemGray3)
        }
        return Color(uiColor: .secondarySystemGroupedBackground)
    }

    private var keyHeight: CGFloat {
        let screen = UIScreen.main.bounds.height
        return screen < 700 ? 52 : 60
    }
}

// MARK: - Pressable Button Style

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}
