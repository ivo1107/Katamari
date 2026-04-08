import SwiftUI

struct ResultView: View {
    @EnvironmentObject var vm: GameViewModel
    @Environment(\.dismiss) private var dismiss

    private var won: Bool { vm.gameState.status == .won }
    private var attempt: Int { vm.gameState.currentRow }
    private var earnedPoints: Int { won ? vm.points(for: attempt) : 0 }

    var body: some View {
        ZStack {
            Color(hex: "121213").ignoresSafeArea()

            VStack(spacing: 28) {
                // Título
                Text(won ? "Parabéns! 🎉" : "Que pena...")
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(.white)

                // Resultado
                if won {
                    VStack(spacing: 6) {
                        Text("Acertaste em \(attempt) tentativa\(attempt == 1 ? "" : "s")")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("+\(earnedPoints) pontos")
                            .font(.system(size: 40, weight: .black))
                            .foregroundColor(.green)
                    }
                } else {
                    VStack(spacing: 6) {
                        Text("A palavra era")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(vm.gameState.targetWord)
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                            .tracking(6)
                    }
                }

                // Mini estatísticas
                let stats = vm.getStats()
                HStack(spacing: 0) {
                    MiniStat(value: "\(stats.gamesPlayed)",   label: "Jogos")
                    MiniStat(value: "\(stats.winRate)%",      label: "Vitórias")
                    MiniStat(value: "\(stats.currentStreak)", label: "Sequência")
                    MiniStat(value: "\(stats.totalScore)",    label: "Pontos")
                }
                .padding()
                .background(Color(hex: "1C1C1E"))
                .cornerRadius(14)
                .padding(.horizontal)

                // Ação
                Button("Jogar Novamente") {
                    vm.startNewGame()
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "538D4E"))
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal)
            }
        }
        .presentationDetents([.medium])
    }
}

private struct MiniStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2).fontWeight(.black)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
