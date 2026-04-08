import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var game: GameViewModel
    @EnvironmentObject var lb: LeaderboardViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Group {
                    if lb.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(lb.entries.enumerated()), id: \.element.id) { idx, entry in
                                    LeaderboardRow(rank: idx + 1, entry: entry,
                                                   highlight: entry.isCurrentUser || entry.id == game.playerId)
                                        .background(
                                            entry.isCurrentUser || entry.id == game.playerId
                                                ? Color(hex: "1A2A1A")
                                                : Color.black
                                        )
                                    Divider().background(Color(hex: "2C2C2E"))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ranking Global")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { lb.load() }
    }
}

// MARK: - Linha do ranking
private struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let highlight: Bool

    private var rankBadge: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Posição
            Group {
                if rank <= 3 {
                    Text(rankBadge).font(.title2)
                } else {
                    Text(rankBadge)
                        .font(.subheadline.bold())
                        .foregroundColor(.gray)
                        .frame(width: 30)
                }
            }
            .frame(width: 36)

            // Info do jogador
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    if highlight {
                        Text("você")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color(hex: "538D4E"))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 8) {
                    Label("\(entry.gamesWon)V", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "538D4E"))
                    Text("\(entry.winRate)%")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if entry.currentStreak > 0 {
                        Text("🔥 \(entry.currentStreak)")
                            .font(.caption)
                    }
                }
            }

            Spacer()

            // Pontuação
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.score)")
                    .font(.title3.bold())
                    .foregroundColor(highlight ? Color(hex: "538D4E") : .white)
                Text("pts")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
