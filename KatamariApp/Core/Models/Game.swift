import Foundation

struct GameState: Codable {
    var roomId: String
    var currentRound: Int
    var currentPlayerIndex: Int
    var currentQuestion: String?
    var roundStatus: RoundStatus
    var guessCount: Int
    var totalPlayers: Int
    var voteYes: Int
    var voteNo: Int
    var votes: [String: String]
    var finishedPlayerIds: [String]

    enum RoundStatus: String, Codable {
        case asking
        case voting
        case showingResult
        case guessing
        case finished
    }

    var totalVotes: Int { voteYes + voteNo }
    var majorityThreshold: Int { (totalPlayers / 2) + 1 }
    var hasReachedMajority: Bool { totalVotes >= majorityThreshold }

    var majorityResult: VoteResult? {
        guard hasReachedMajority else { return nil }
        return voteYes > voteNo ? .yes : .no
    }

    init(roomId: String, totalPlayers: Int) {
        self.roomId = roomId
        self.currentRound = 1
        self.currentPlayerIndex = 0
        self.currentQuestion = nil
        self.roundStatus = .asking
        self.guessCount = 0
        self.totalPlayers = totalPlayers
        self.voteYes = 0
        self.voteNo = 0
        self.votes = [:]
        self.finishedPlayerIds = []
    }
}

enum VoteResult: String, Codable {
    case yes = "Sim"
    case no  = "Não"
}
