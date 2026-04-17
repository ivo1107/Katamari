import SwiftUI

struct RoundResultView: View {
    let question: String
    let result: VoteResult?
    let yesVotes: Int
    let noVotes: Int

    var body: some View {
        VStack(spacing: 16) {
            Text("Resultado da Rodada")
                .font(.headline.bold())
                .foregroundStyle(KatamariTheme.Colors.label)

            Text("\"\(question)\"")
                .font(.subheadline)
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .italic()

            if let result {
                VStack(spacing: 8) {
                    Text(result == .yes ? "✅" : "❌")
                        .font(.system(size: 48))
                    Text(result.rawValue.uppercased())
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(result == .yes ? .green : .red)
                }
                .padding(20)
                .background(
                    (result == .yes ? Color.green : Color.red).opacity(0.1)
                )
                .cornerRadius(16)
            }

            HStack(spacing: 32) {
                voteCount(count: yesVotes, label: "Sim", color: .green,
                          icon: "hand.thumbsup.fill")
                voteCount(count: noVotes, label: "Não", color: .red,
                          icon: "hand.thumbsdown.fill")
            }
        }
        .padding(20)
        .background(KatamariTheme.Colors.cardBackground)
        .cornerRadius(16)
        .transition(.scale.combined(with: .opacity))
    }

    private func voteCount(count: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.title.bold())
                .foregroundStyle(KatamariTheme.Colors.label)
            Text(label)
                .font(.caption)
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
        }
    }
}
