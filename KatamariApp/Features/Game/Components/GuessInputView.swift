import SwiftUI

struct GuessInputView: View {
    @Binding var guessText: String
    let isSubmitting: Bool
    let onGuess: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("🎯")
                    .font(.system(size: 40))
                Text("Hora de adivinhar!")
                    .font(.title3.bold())
                    .foregroundStyle(KatamariTheme.Colors.label)
                Text("Você acumulou pistas suficientes.\nQual é a sua palavra?")
                    .font(.subheadline)
                    .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }

            TextField("Seu palpite...", text: $guessText)
                .textFieldStyle(.plain)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(16)
                .background(KatamariTheme.Colors.background)
                .cornerRadius(12)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .submitLabel(.go)
                .onSubmit { if !guessText.isEmpty { onGuess() } }
                .onAppear { isFocused = true }

            KatamariButton(
                title: isSubmitting ? "Verificando..." : "Confirmar Resposta",
                icon: "checkmark.seal.fill",
                style: .accent,
                isLoading: isSubmitting,
                isDisabled: guessText.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                isFocused = false
                onGuess()
            }
        }
        .padding(20)
        .background(KatamariTheme.Colors.cardBackground)
        .cornerRadius(16)
    }
}
