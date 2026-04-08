import Foundation

struct LeaderboardEntry: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var score: Int
    var gamesPlayed: Int
    var gamesWon: Int
    var currentStreak: Int
    var maxStreak: Int
    var isCurrentUser: Bool

    var winRate: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int(Double(gamesWon) / Double(gamesPlayed) * 100)
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        score: Int = 0,
        gamesPlayed: Int = 0,
        gamesWon: Int = 0,
        currentStreak: Int = 0,
        maxStreak: Int = 0,
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.name = name
        self.score = score
        self.gamesPlayed = gamesPlayed
        self.gamesWon = gamesWon
        self.currentStreak = currentStreak
        self.maxStreak = maxStreak
        self.isCurrentUser = isCurrentUser
    }
}

struct PlayerStats {
    let gamesPlayed: Int
    let gamesWon: Int
    let currentStreak: Int
    let maxStreak: Int
    let totalScore: Int

    var winRate: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int(Double(gamesWon) / Double(gamesPlayed) * 100)
    }
}
