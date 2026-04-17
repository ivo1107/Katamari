import SwiftUI

struct GameView: View {
    let roomId: String
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authRepository: FirebaseAuthRepository
    @StateObject private var viewModel: GameViewModel

    init(roomId: String) {
        self.roomId = roomId
        _viewModel = StateObject(wrappedValue: GameViewModel(
            roomId: roomId,
            roomRepository: FirebaseRoomRepository(),
            gameRepository: FirebaseGameRepository(),
            authRepository: FirebaseAuthRepository()
        ))
    }

    var body: some View {
        ZStack {
            KatamariTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                gameHeader
                ScrollView {
                    VStack(spacing: 16) {
                        playersWordGrid
                        currentRoundPanel
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }

            if viewModel.showGuessResult {
                guessResultOverlay
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.gameFinished) { _, finished in
            if finished { router.navigate(to: .results(roomId: roomId)) }
        }
        .alert("Erro", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Header

    private var gameHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rodada \(viewModel.gameState?.currentRound ?? 1)")
                    .font(.headline.bold())
                    .foregroundStyle(KatamariTheme.Colors.label)
                if let player = viewModel.currentAskingPlayer {
                    Text(viewModel.isMyTurn ? "Sua vez!" : "Vez de \(player.displayName)")
                        .font(.caption)
                        .foregroundStyle(
                            viewModel.isMyTurn
                                ? KatamariTheme.Colors.primary
                                : KatamariTheme.Colors.secondaryLabel
                        )
                }
            }
            Spacer()
            LiveScoreChip(players: viewModel.sortedPlayers)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(KatamariTheme.Colors.cardBackground)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Players word grid

    private var playersWordGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Palavras dos jogadores")
                .font(.subheadline.bold())
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(viewModel.otherPlayers) { player in
                    PlayerWordCard(player: player,
                                   isAsking: player.id == viewModel.currentAskingPlayer?.id)
                }
                MyWordCard(player: viewModel.myPlayer)
            }
        }
    }

    // MARK: - Round panel (switches based on phase)

    @ViewBuilder
    private var currentRoundPanel: some View {
        switch viewModel.roundPhase {
        case .asking:
            if viewModel.isMyTurn {
                QuestionInputView(
                    questionText: $viewModel.questionText,
                    isSubmitting: viewModel.isSubmittingQuestion,
                    guessText: $viewModel.guessText,
                    isSubmittingGuess: viewModel.isSubmittingGuess
                ) {
                    Task { await viewModel.submitQuestion() }
                } onGuess: {
                    Task { await viewModel.submitGuess() }
                }
            } else {
                WaitingForQuestionView(playerName: viewModel.currentAskingPlayer?.displayName ?? "")
            }

        case .voting:
            VotingPanelView(
                question: viewModel.gameState?.currentQuestion ?? "",
                askingPlayerName: viewModel.currentAskingPlayer?.displayName ?? "",
                voteProgress: viewModel.voteProgress,
                totalVotes: viewModel.gameState?.totalVotes ?? 0,
                totalPlayers: viewModel.gameState?.totalPlayers ?? 0,
                hasVoted: viewModel.hasVoted,
                isMyTurn: viewModel.isMyTurn,
                isSubmitting: viewModel.isSubmittingVote
            ) { vote in
                Task { await viewModel.submitVote(vote) }
            }

        case .showingResult:
            RoundResultView(
                question: viewModel.gameState?.currentQuestion ?? "",
                result: viewModel.gameState?.majorityResult,
                yesVotes: viewModel.gameState?.voteYes ?? 0,
                noVotes: viewModel.gameState?.voteNo ?? 0
            )

        case .guessing:
            if viewModel.isMyTurn {
                GuessInputView(
                    guessText: $viewModel.guessText,
                    isSubmitting: viewModel.isSubmittingGuess
                ) {
                    Task { await viewModel.submitGuess() }
                }
            } else {
                WaitingForGuessView(playerName: viewModel.currentAskingPlayer?.displayName ?? "")
            }

        case .finished:
            EmptyView()
        }
    }

    // MARK: - Guess result overlay

    private var guessResultOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 20) {
                switch viewModel.guessResult {
                case .correct(let word):
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                    Text("Você acertou! 🎉")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("Você é \(word)!")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                case .wrong:
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.red)
                    Text("Quase lá!")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("Continue tentando...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                case .none:
                    EmptyView()
                }
                Button("Continuar") {
                    viewModel.showGuessResult = false
                    viewModel.guessResult = nil
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.2))
                .cornerRadius(14)
            }
            .padding(32)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(duration: 0.4), value: viewModel.showGuessResult)
    }
}

// MARK: - Supporting views

struct PlayerWordCard: View {
    let player: RoomPlayer
    let isAsking: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                PlayerAvatar(initials: player.initials, size: 28,
                             color: isAsking ? KatamariTheme.Colors.primary : KatamariTheme.Colors.secondary)
                Spacer()
                if player.hasGuessed {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                if isAsking {
                    Image(systemName: "mic.fill")
                        .font(.caption)
                        .foregroundStyle(KatamariTheme.Colors.primary)
                }
            }
            if let word = player.word {
                Text(word)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(player.hasGuessed ? .green : KatamariTheme.Colors.label)
                    .strikethrough(player.hasGuessed)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                Text("???")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
            }
            Text(player.displayName)
                .font(.caption2)
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            isAsking
                ? KatamariTheme.Colors.primary.opacity(0.1)
                : KatamariTheme.Colors.cardBackground
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isAsking ? KatamariTheme.Colors.primary.opacity(0.5) : .clear, lineWidth: 1.5)
        )
    }
}

struct MyWordCard: View {
    let player: RoomPlayer?

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                PlayerAvatar(initials: player?.initials ?? "?", size: 28,
                             color: KatamariTheme.Colors.accent)
                Spacer()
                if player?.hasGuessed == true {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            Image(systemName: "eye.slash.fill")
                .font(.title3)
                .foregroundStyle(KatamariTheme.Colors.accent.opacity(0.8))
            Text(player?.hasGuessed == true ? (player?.word ?? "???") : "Você")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(
                    player?.hasGuessed == true ? .green : KatamariTheme.Colors.accent
                )
            Text("(sua palavra)")
                .font(.caption2)
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(KatamariTheme.Colors.accent.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(KatamariTheme.Colors.accent.opacity(0.3), lineWidth: 1.5)
        )
    }
}

struct WaitingForQuestionView: View {
    let playerName: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(KatamariTheme.Colors.primary)
            Text("\(playerName) está formulando uma pergunta...")
                .font(.subheadline)
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(KatamariTheme.Colors.cardBackground)
        .cornerRadius(16)
    }
}

struct WaitingForGuessView: View {
    let playerName: String

    var body: some View {
        VStack(spacing: 12) {
            Text("🤔")
                .font(.system(size: 40))
            Text("\(playerName) está tentando adivinhar...")
                .font(.subheadline)
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(KatamariTheme.Colors.cardBackground)
        .cornerRadius(16)
    }
}

struct LiveScoreChip: View {
    let players: [RoomPlayer]

    var body: some View {
        HStack(spacing: -8) {
            ForEach(players.prefix(3)) { player in
                PlayerAvatar(initials: player.initials, size: 32,
                             color: KatamariTheme.Colors.primary)
                    .overlay(
                        Circle().stroke(KatamariTheme.Colors.cardBackground, lineWidth: 2)
                    )
            }
        }
    }
}
