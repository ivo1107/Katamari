import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    // MARK: - Published state
    @Published var room: Room?
    @Published var gameState: GameState?
    @Published var rounds: [Round] = []
    @Published var isSubmittingQuestion = false
    @Published var isSubmittingVote = false
    @Published var isSubmittingGuess = false
    @Published var guessText = ""
    @Published var questionText = ""
    @Published var errorMessage: String?
    @Published var guessResult: GuessResult?
    @Published var showGuessResult = false
    @Published var gameFinished = false
    @Published var hasVoted = false

    enum GuessResult {
        case correct(word: String)
        case wrong
    }

    // MARK: - Dependencies
    let roomId: String
    private let roomRepository: FirebaseRoomRepository
    private let gameRepository: FirebaseGameRepository
    private let authRepository: FirebaseAuthRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed
    var currentUser: KatamariUser? { authRepository.currentUser }

    var myPlayer: RoomPlayer? {
        room?.players.first { $0.id == currentUser?.id }
    }

    var otherPlayers: [RoomPlayer] {
        room?.players.filter { $0.id != currentUser?.id } ?? []
    }

    var currentAskingPlayer: RoomPlayer? {
        guard let state = gameState, let room else { return nil }
        let idx = state.currentPlayerIndex % room.players.count
        return room.players[safe: idx]
    }

    var isMyTurn: Bool {
        currentAskingPlayer?.id == currentUser?.id
    }

    var roundPhase: GameState.RoundStatus {
        gameState?.roundStatus ?? .asking
    }

    var voteProgress: Double {
        guard let state = gameState, state.totalPlayers > 0 else { return 0 }
        return Double(state.totalVotes) / Double(state.totalPlayers)
    }

    var sortedPlayers: [RoomPlayer] {
        (room?.players ?? []).sorted {
            ($0.guessOrder ?? Int.max) < ($1.guessOrder ?? Int.max)
        }
    }

    // MARK: - Init

    init(roomId: String,
         roomRepository: FirebaseRoomRepository,
         gameRepository: FirebaseGameRepository,
         authRepository: FirebaseAuthRepository) {
        self.roomId = roomId
        self.roomRepository = roomRepository
        self.gameRepository = gameRepository
        self.authRepository = authRepository
        observeAll()
    }

    // MARK: - Observation

    private func observeAll() {
        roomRepository.observeRoom(roomId: roomId)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] room in
                self?.room = room
                if room.status == .finished { self?.gameFinished = true }
            }
            .store(in: &cancellables)

        gameRepository.observeGameState(roomId: roomId)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] state in
                guard let self else { return }
                let previous = self.gameState
                self.gameState = state

                self.handleStateTransition(from: previous, to: state)
            }
            .store(in: &cancellables)

        gameRepository.observeRounds(roomId: roomId)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] rounds in
                self?.rounds = rounds
            }
            .store(in: &cancellables)
    }

    private func handleStateTransition(from previous: GameState?, to current: GameState) {
        guard let previous else { return }

        if previous.roundStatus != .voting && current.roundStatus == .voting {
            HapticService.shared.playRoundAdvance()
            hasVoted = false
            if !isMyTurn {
                NotificationService.shared.scheduleLocalVoteNotification()
            }
        }

        if previous.roundStatus != .showingResult && current.roundStatus == .showingResult {
            HapticService.shared.notification(.success)
        }

        if previous.currentPlayerIndex != current.currentPlayerIndex {
            HapticService.shared.playRoundAdvance()
            hasVoted = false
            questionText = ""
            guessText = ""
        }

        if current.roundStatus == .finished {
            gameFinished = true
        }
    }

    // MARK: - Actions

    func submitQuestion() async {
        guard let userId = currentUser?.id, !questionText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSubmittingQuestion = true
        defer { isSubmittingQuestion = false }
        do {
            try await gameRepository.submitQuestion(roomId: roomId, playerId: userId,
                                                     question: questionText.trimmingCharacters(in: .whitespaces))
            HapticService.shared.impact(.medium)
            questionText = ""
        } catch {
            errorMessage = error.localizedDescription
            HapticService.shared.notification(.error)
        }
    }

    func submitVote(_ vote: VoteResult) async {
        guard let userId = currentUser?.id, !hasVoted else { return }
        isSubmittingVote = true
        hasVoted = true
        defer { isSubmittingVote = false }
        do {
            try await gameRepository.submitVote(roomId: roomId, playerId: userId, vote: vote)
            HapticService.shared.playVoteSuccess()
        } catch {
            hasVoted = false
            errorMessage = error.localizedDescription
            HapticService.shared.notification(.error)
        }
    }

    func submitGuess() async {
        guard let userId = currentUser?.id,
              !guessText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSubmittingGuess = true
        defer { isSubmittingGuess = false }
        do {
            let correct = try await gameRepository.submitGuess(
                roomId: roomId, playerId: userId,
                guess: guessText.trimmingCharacters(in: .whitespaces)
            )
            if correct {
                guessResult = .correct(word: guessText)
                HapticService.shared.playCorrectGuess()
            } else {
                guessResult = .wrong
                HapticService.shared.playWrongGuess()
            }
            showGuessResult = true
            guessText = ""
        } catch {
            errorMessage = error.localizedDescription
            HapticService.shared.notification(.error)
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
