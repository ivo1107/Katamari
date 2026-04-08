import Foundation

struct GameRow: Identifiable {
    let id = UUID()
    var letters: [Letter]

    init() {
        letters = Array(repeating: Letter(), count: 5)
    }
}

enum GameStatus {
    case playing
    case won
    case lost
}

struct GameState {
    var rows: [GameRow]
    var currentRow: Int
    var currentCol: Int
    var targetWord: String
    var status: GameStatus

    init(targetWord: String) {
        rows = Array(repeating: GameRow(), count: 6)
        currentRow = 0
        currentCol = 0
        self.targetWord = targetWord.uppercased()
        status = .playing
    }

    var isGameOver: Bool { status != .playing }
}
