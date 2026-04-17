import SwiftUI

struct QuestionInputView: View {
    @Binding var questionText: String
    let isSubmitting: Bool
    @Binding var guessText: String
    let isSubmittingGuess: Bool
    let onAsk: () -> Void
    let onGuess: () -> Void

    @State private var mode: Mode = .question
    @FocusState private var isFocused: Bool

    enum Mode { case question, guess }

    var body: some View {
        VStack(spacing: 16) {
            modeSelector
            if mode == .question {
                questionPanel
            } else {
                guessPanel
            }
        }
        .padding(16)
        .background(KatamariTheme.Colors.cardBackground)
        .cornerRadius(16)
    }

    private var modeSelector: some View {
        HStack(spacing: 0) {
            modeTab(title: "Fazer Pergunta", icon: "questionmark.bubble.fill", tab: .question)
            modeTab(title: "Adivinhar", icon: "lightbulb.fill", tab: .guess)
        }
        .background(KatamariTheme.Colors.background)
        .cornerRadius(10)
        .padding(2)
        .background(KatamariTheme.Colors.separator.opacity(0.3))
        .cornerRadius(12)
    }

    private func modeTab(title: String, icon: String, tab: Mode) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25)) { mode = tab }
            HapticService.shared.selection()
        } label: {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(mode == tab ? .white : KatamariTheme.Colors.secondaryLabel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    mode == tab
                        ? (tab == .question ? KatamariTheme.Colors.primary : KatamariTheme.Colors.accent)
                        : .clear
                )
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var questionPanel: some View {
        VStack(spacing: 12) {
            Text("Faça uma pergunta de Sim ou Não")
                .font(.caption)
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)

            TextField("Ex: Sou uma pessoa famosa?", text: $questionText, axis: .vertical)
                .lineLimit(3)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(12)
                .background(KatamariTheme.Colors.background)
                .cornerRadius(10)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { if !questionText.isEmpty { onAsk() } }

            KatamariButton(
                title: isSubmitting ? "Enviando..." : "Fazer Pergunta",
                icon: "paperplane.fill",
                style: .primary,
                isLoading: isSubmitting,
                isDisabled: questionText.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                isFocused = false
                onAsk()
            }
        }
    }

    private var guessPanel: some View {
        VStack(spacing: 12) {
            Text("Qual é a sua palavra?")
                .font(.caption)
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)

            TextField("Digite seu palpite...", text: $guessText)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(12)
                .background(KatamariTheme.Colors.background)
                .cornerRadius(10)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit { if !guessText.isEmpty { onGuess() } }

            KatamariButton(
                title: isSubmittingGuess ? "Verificando..." : "Tentar Adivinhar",
                icon: "checkmark.circle.fill",
                style: .accent,
                isLoading: isSubmittingGuess,
                isDisabled: guessText.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                isFocused = false
                onGuess()
            }
        }
    }
}
