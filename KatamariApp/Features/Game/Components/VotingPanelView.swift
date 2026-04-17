import SwiftUI

struct VotingPanelView: View {
    let question: String
    let askingPlayerName: String
    let voteProgress: Double
    let totalVotes: Int
    let totalPlayers: Int
    let hasVoted: Bool
    let isMyTurn: Bool
    let isSubmitting: Bool
    let onVote: (VoteResult) -> Void

    var body: some View {
        VStack(spacing: 16) {
            questionDisplay
            progressSection
            if !isMyTurn {
                voteButtons
            } else {
                Text("Aguarde os outros jogadores votarem")
                    .font(.caption)
                    .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(KatamariTheme.Colors.cardBackground)
        .cornerRadius(16)
    }

    private var questionDisplay: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.bubble.fill")
                    .foregroundStyle(KatamariTheme.Colors.primary)
                Text(askingPlayerName + " pergunta:")
                    .font(.caption.bold())
                    .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
            }
            Text("\"\(question)\"")
                .font(.headline)
                .foregroundStyle(KatamariTheme.Colors.label)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Votos: \(totalVotes)/\(totalPlayers)")
                    .font(.caption)
                    .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                Spacer()
                Text("Maioria: \((totalPlayers / 2) + 1) votos")
                    .font(.caption)
                    .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(KatamariTheme.Colors.separator.opacity(0.3))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(KatamariTheme.Colors.primary)
                        .frame(width: geo.size.width * voteProgress)
                        .animation(.spring(duration: 0.4), value: voteProgress)
                }
            }
            .frame(height: 6)
        }
    }

    private var voteButtons: some View {
        HStack(spacing: 12) {
            VoteButton(
                title: "Sim",
                icon: "hand.thumbsup.fill",
                color: .green,
                isSelected: hasVoted,
                isDisabled: hasVoted || isSubmitting
            ) {
                onVote(.yes)
            }
            VoteButton(
                title: "Não",
                icon: "hand.thumbsdown.fill",
                color: .red,
                isSelected: hasVoted,
                isDisabled: hasVoted || isSubmitting
            ) {
                onVote(.no)
            }
        }
    }
}
