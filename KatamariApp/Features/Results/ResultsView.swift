import SwiftUI

struct ResultsView: View {
    let roomId: String
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authRepository: FirebaseAuthRepository
    @StateObject private var viewModel: ResultsViewModel

    init(roomId: String) {
        self.roomId = roomId
        _viewModel = StateObject(wrappedValue: ResultsViewModel(
            roomId: roomId,
            roomRepository: FirebaseRoomRepository(),
            scoreRepository: FirebaseScoreRepository(),
            authRepository: FirebaseAuthRepository()
        ))
    }

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    winnerAnnouncement
                    myResultCard
                    fullLeaderboard
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                KatamariTheme.Colors.primary.opacity(0.15),
                KatamariTheme.Colors.background,
                KatamariTheme.Colors.background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var winnerAnnouncement: some View {
        VStack(spacing: 12) {
            Text("🏆")
                .font(.system(size: 64))
            if let winner = viewModel.winner {
                Text("Vencedor")
                    .font(.caption.bold())
                    .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                    .textCase(.uppercase)
                    .tracking(2)
                Text(winner.id == authRepository.currentUser?.id ? "Você!" : winner.displayName)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(KatamariTheme.Colors.label)
                if let word = winner.word {
                    Text("era \"\(word)\"")
                        .font(.title3)
                        .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                }
            } else {
                Text("Partida Encerrada")
                    .font(.title.bold())
                    .foregroundStyle(KatamariTheme.Colors.label)
            }
        }
        .multilineTextAlignment(.center)
    }

    private var myResultCard: some View {
        Group {
            if let my = viewModel.myResult {
                VStack(spacing: 12) {
                    Text("Seu Resultado")
                        .font(.caption.bold())
                        .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                        .textCase(.uppercase)
                        .tracking(2)

                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text(my.hasGuessed ? "✅" : "❌")
                                .font(.title)
                            Text(my.hasGuessed ? "Acertou!" : "Não acertou")
                                .font(.caption.bold())
                                .foregroundStyle(KatamariTheme.Colors.label)
                        }
                        Divider().frame(height: 44)
                        VStack(spacing: 4) {
                            Text("\(my.points)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(KatamariTheme.Colors.primary)
                            Text("pontos")
                                .font(.caption)
                                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                        }
                        Divider().frame(height: 44)
                        VStack(spacing: 4) {
                            if let word = my.word {
                                Text(word)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(KatamariTheme.Colors.label)
                            }
                            Text("sua palavra")
                                .font(.caption)
                                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                        }
                    }
                }
                .padding(20)
                .background(KatamariTheme.Colors.cardBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            }
        }
    }

    private var fullLeaderboard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Placar Final")
                .font(.title3.bold())
                .foregroundStyle(KatamariTheme.Colors.label)

            VStack(spacing: 8) {
                ForEach(Array(viewModel.sortedPlayers.enumerated()), id: \.element.id) { index, player in
                    ResultPlayerRow(
                        position: index + 1,
                        player: player,
                        isCurrentUser: player.id == authRepository.currentUser?.id
                    )
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            KatamariButton(
                title: "Ver Ranking Global",
                icon: "trophy.fill",
                style: .secondary
            ) {
                HapticService.shared.impact(.light)
                router.navigate(to: .ranking)
            }
            KatamariButton(
                title: "Voltar ao Início",
                icon: "house.fill",
                style: .primary
            ) {
                HapticService.shared.impact(.medium)
                router.popToRoot()
            }
        }
    }
}

struct ResultPlayerRow: View {
    let position: Int
    let player: RoomPlayer
    let isCurrentUser: Bool

    private var positionEmoji: String {
        switch position { case 1: return "🥇"; case 2: return "🥈"; case 3: return "🥉"; default: return "\(position)º" }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(positionEmoji)
                .font(.title3)
                .frame(width: 32)

            PlayerAvatar(initials: player.initials, size: 36,
                         color: isCurrentUser ? KatamariTheme.Colors.primary : KatamariTheme.Colors.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrentUser ? "Você" : player.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(KatamariTheme.Colors.label)
                if let word = player.word {
                    Text("era \"\(word)\"")
                        .font(.caption)
                        .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.points) pts")
                    .font(.subheadline.bold())
                    .foregroundStyle(player.hasGuessed ? KatamariTheme.Colors.primary : KatamariTheme.Colors.secondaryLabel)
                Text(player.hasGuessed ? "✓ Acertou" : "✗ Não acertou")
                    .font(.caption)
                    .foregroundStyle(player.hasGuessed ? .green : .red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            isCurrentUser
                ? KatamariTheme.Colors.primary.opacity(0.08)
                : KatamariTheme.Colors.cardBackground
        )
        .cornerRadius(12)
    }
}
