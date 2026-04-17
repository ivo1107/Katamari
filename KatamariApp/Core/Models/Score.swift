import Foundation

struct GlobalScore: Identifiable, Codable {
    let id: String
    var userId: String
    var displayName: String
    var totalPoints: Int
    var gamesPlayed: Int
    var wins: Int
    var rank: Int?

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(wins) / Double(gamesPlayed) * 100
    }
}

struct GameResult: Identifiable, Codable {
    let id: String
    var roomId: String
    var category: WordCategory
    var playerResults: [PlayerResult]
    var finishedAt: Date

    var winner: PlayerResult? {
        playerResults.min(by: { ($0.guessOrder ?? Int.max) < ($1.guessOrder ?? Int.max) })
    }
}

struct PlayerResult: Identifiable, Codable {
    let id: String
    var userId: String
    var displayName: String
    var word: String
    var guessOrder: Int?
    var pointsEarned: Int
    var hasGuessed: Bool

    static func points(for order: Int?) -> Int {
        switch order {
        case 1:     return 100
        case 2:     return 70
        case 3:     return 50
        case .some: return 30
        case .none: return 0
        }
    }
}
