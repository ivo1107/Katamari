import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Estado publicado
    @Published var gameState: GameState
    @Published var usedLetters: [Character: LetterState] = [:]
    @Published var showResult = false
    @Published var showMessage = false
    @Published var message = ""
    @Published var isShaking = false
    @Published var score = 0
    @Published var playerName = ""
    @Published var playerId = ""

    // MARK: - Dependências
    private let wordService = WordService.shared
    private let leaderboardService: LeaderboardServiceProtocol = LeaderboardService.shared
    private let ud = UserDefaults.standard

    // MARK: - Init
    init() {
        let storedName = UserDefaults.standard.string(forKey: "playerName") ?? ""
        var storedId = UserDefaults.standard.string(forKey: "playerId") ?? ""
        if storedId.isEmpty {
            storedId = UUID().uuidString
            UserDefaults.standard.set(storedId, forKey: "playerId")
        }
        playerName = storedName
        playerId = storedId
        score = UserDefaults.standard.integer(forKey: "totalScore")
        gameState = GameState(targetWord: WordService.shared.getWordOfDay())
    }

    // MARK: - Ações do jogo

    func addLetter(_ char: Character) {
        guard !gameState.isGameOver, gameState.currentCol < 5 else { return }
        gameState.rows[gameState.currentRow].letters[gameState.currentCol].character = char
        gameState.rows[gameState.currentRow].letters[gameState.currentCol].state = .filled
        gameState.currentCol += 1
    }

    func removeLetter() {
        guard !gameState.isGameOver, gameState.currentCol > 0 else { return }
        gameState.currentCol -= 1
        gameState.rows[gameState.currentRow].letters[gameState.currentCol].character = " "
        gameState.rows[gameState.currentRow].letters[gameState.currentCol].state = .empty
    }

    func submitGuess() {
        guard !gameState.isGameOver else { return }
        guard gameState.currentCol == 5 else {
            flash("Palavra incompleta")
            triggerShake()
            return
        }
        let guess = currentGuessWord()
        guard wordService.isValidWord(guess) else {
            flash("Palavra não encontrada")
            triggerShake()
            return
        }
        evaluateGuess(guess)
    }

    func startNewGame() {
        gameState = GameState(targetWord: wordService.randomWord())
        usedLetters = [:]
        showResult = false
    }

    func setPlayerName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        playerName = trimmed
        ud.set(trimmed, forKey: "playerName")
    }

    func getStats() -> PlayerStats {
        PlayerStats(
            gamesPlayed:   ud.integer(forKey: "gamesPlayed"),
            gamesWon:      ud.integer(forKey: "gamesWon"),
            currentStreak: ud.integer(forKey: "currentStreak"),
            maxStreak:     ud.integer(forKey: "maxStreak"),
            totalScore:    score
        )
    }

    // MARK: - Privado

    private func currentGuessWord() -> String {
        gameState.rows[gameState.currentRow].letters.map { String($0.character) }.joined()
    }

    private func evaluateGuess(_ guess: String) {
        let target     = Array(gameState.targetWord)
        let guessChars = Array(guess.uppercased())
        var results: [LetterState] = Array(repeating: .absent, count: 5)
        var targetCopy = target
        var guessCopy  = guessChars

        // 1ª passagem: posições corretas
        for i in 0..<5 where guessCopy[i] == targetCopy[i] {
            results[i]    = .correct
            targetCopy[i] = Character("*")
            guessCopy[i]  = Character("_")
        }

        // 2ª passagem: letras presentes em posição errada
        for i in 0..<5 where guessCopy[i] != Character("_") {
            if let idx = targetCopy.firstIndex(of: guessCopy[i]) {
                results[i]    = .present
                targetCopy[idx] = Character("*")
            }
        }

        // Aplica resultados nas células
        for i in 0..<5 {
            gameState.rows[gameState.currentRow].letters[i].state = results[i]
        }

        // Atualiza estado das teclas (verde > amarelo > cinza)
        for (i, char) in guessChars.enumerated() {
            let new = results[i]
            switch usedLetters[char] {
            case .none:    usedLetters[char] = new
            case .correct: break
            case .present: if new == .correct { usedLetters[char] = new }
            default:       if new == .correct || new == .present { usedLetters[char] = new }
            }
        }

        let won       = results.allSatisfy { $0 == .correct }
        let isLastRow = gameState.currentRow == 5

        gameState.currentRow += 1
        gameState.currentCol = 0

        if won {
            score += points(for: gameState.currentRow)
            gameState.status = .won
            saveStats(won: true)
            Task { await leaderboardService.updatePlayerScore(
                id: playerId, name: playerName, score: score, stats: getStats()
            )}
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.showResult = true }
        } else if isLastRow {
            gameState.status = .lost
            saveStats(won: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.showResult = true }
        }
    }

    // Pontuação: menor número de tentativas = mais pontos
    func points(for attempt: Int) -> Int {
        switch attempt {
        case 1: return 100
        case 2: return 80
        case 3: return 60
        case 4: return 40
        case 5: return 20
        case 6: return 10
        default: return 0
        }
    }

    private func saveStats(won: Bool) {
        let played  = ud.integer(forKey: "gamesPlayed") + 1
        var wonCount = ud.integer(forKey: "gamesWon")
        var streak   = ud.integer(forKey: "currentStreak")
        var maxStrk  = ud.integer(forKey: "maxStreak")

        if won {
            wonCount += 1
            streak   += 1
            maxStrk   = max(maxStrk, streak)
        } else {
            streak = 0
        }

        ud.set(played,   forKey: "gamesPlayed")
        ud.set(wonCount, forKey: "gamesWon")
        ud.set(streak,   forKey: "currentStreak")
        ud.set(maxStrk,  forKey: "maxStreak")
        ud.set(score,    forKey: "totalScore")
    }

    private func flash(_ text: String) {
        message     = text
        showMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { self.showMessage = false }
    }

    private func triggerShake() {
        isShaking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.isShaking = false }
    }
}
