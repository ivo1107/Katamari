import SwiftUI

struct RankingView: View {
    @EnvironmentObject var authRepository: FirebaseAuthRepository
    @StateObject private var viewModel = RankingViewModel(
        scoreRepository: FirebaseScoreRepository(),
        authRepository: FirebaseAuthRepository()
    )

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let my = viewModel.myScore ?? viewModel.globalRanking.first(where: {
                    $0.userId == authRepository.currentUser?.id
                }) {
                    myScoreCard(my)
                }
                podiumSection
                fullRankingList
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(KatamariTheme.Colors.background)
        .navigationTitle("Ranking Global")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .background(KatamariTheme.Colors.background.opacity(0.5))
            }
        }
    }

    private func myScoreCard(_ score: GlobalScore) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(KatamariTheme.Colors.primary.opacity(0.15))
                    .frame(width: 56, height: 56)
                Text(score.displayName.prefix(2).uppercased())
                    .font(.headline.bold())
                    .foregroundStyle(KatamariTheme.Colors.primary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Seu Ranking")
                    .font(.caption)
                    .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                Text("#\(score.rank ?? 0)")
                    .font(.title.bold())
                    .foregroundStyle(KatamariTheme.Colors.primary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(score.totalPoints) pts")
                    .font(.title3.bold())
                    .foregroundStyle(KatamariTheme.Colors.label)
                Text("\(score.gamesPlayed) partidas")
                    .font(.caption)
                    .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [KatamariTheme.Colors.primary.opacity(0.15),
                         KatamariTheme.Colors.secondary.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(KatamariTheme.Colors.primary.opacity(0.3), lineWidth: 1.5)
        )
    }

    private var podiumSection: some View {
        let top3 = Array(viewModel.globalRanking.prefix(3))
        return Group {
            if top3.count >= 1 {
                HStack(alignment: .bottom, spacing: 8) {
                    if top3.count >= 2 {
                        PodiumBlock(score: top3[1], position: 2, height: 80)
                    }
                    PodiumBlock(score: top3[0], position: 1, height: 100)
                    if top3.count >= 3 {
                        PodiumBlock(score: top3[2], position: 3, height: 64)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var fullRankingList: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.globalRanking.dropFirst(3)) { score in
                RankingRow(
                    score: score,
                    isCurrentUser: score.userId == authRepository.currentUser?.id
                )
            }
        }
    }
}

struct PodiumBlock: View {
    let score: GlobalScore
    let position: Int
    let height: CGFloat

    private var medal: String {
        switch position { case 1: return "🥇"; case 2: return "🥈"; default: return "🥉" }
    }
    private var color: Color {
        switch position {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        default: return Color(red: 0.8, green: 0.5, blue: 0.2)
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(medal).font(.title2)
            PlayerAvatar(initials: String(score.displayName.prefix(2)).uppercased(),
                         size: 40, color: color)
            Text(score.displayName)
                .font(.caption.bold())
                .foregroundStyle(KatamariTheme.Colors.label)
                .lineLimit(1)
            Text("\(score.totalPoints)")
                .font(.caption2.bold())
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
            Rectangle()
                .fill(color.opacity(0.7))
                .frame(height: height)
                .cornerRadius(6)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RankingRow: View {
    let score: GlobalScore
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("#\(score.rank ?? 0)")
                .font(.subheadline.bold())
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                .frame(width: 36, alignment: .trailing)

            PlayerAvatar(initials: String(score.displayName.prefix(2)).uppercased(),
                         size: 36, color: KatamariTheme.Colors.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrentUser ? "Você" : score.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(KatamariTheme.Colors.label)
                Text("\(score.gamesPlayed) partidas · \(Int(score.winRate))% vitórias")
                    .font(.caption)
                    .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
            }
            Spacer()
            Text("\(score.totalPoints) pts")
                .font(.subheadline.bold())
                .foregroundStyle(KatamariTheme.Colors.primary)
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
