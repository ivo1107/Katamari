import Foundation

// MARK: - Protocol
// Para trocar por Firebase / Supabase / qualquer backend real, basta criar
// outra classe que implemente este protocolo e injetar no LeaderboardViewModel.
protocol LeaderboardServiceProtocol {
    func fetchLeaderboard() async -> [LeaderboardEntry]
    func updatePlayerScore(id: String, name: String, score: Int, stats: PlayerStats) async
}

// MARK: - Implementação local (mock global + dados reais do usuário em UserDefaults)
final class LeaderboardService: LeaderboardServiceProtocol {
    static let shared = LeaderboardService()
    private init() {}

    private let userDefaults = UserDefaults.standard
    private let currentUserKey = "currentUserLeaderboard"

    // Jogadores fictícios simulando um ranking global
    private let mockPlayers: [LeaderboardEntry] = [
        LeaderboardEntry(id: "m01", name: "João Silva",       score: 3420, gamesPlayed: 68, gamesWon: 61, currentStreak: 12, maxStreak: 23),
        LeaderboardEntry(id: "m02", name: "Maria Santos",     score: 2980, gamesPlayed: 55, gamesWon: 49, currentStreak:  5, maxStreak: 18),
        LeaderboardEntry(id: "m03", name: "Carlos Oliveira",  score: 2750, gamesPlayed: 52, gamesWon: 44, currentStreak:  8, maxStreak: 14),
        LeaderboardEntry(id: "m04", name: "Ana Costa",        score: 2340, gamesPlayed: 48, gamesWon: 39, currentStreak:  3, maxStreak: 11),
        LeaderboardEntry(id: "m05", name: "Pedro Alves",      score: 2100, gamesPlayed: 45, gamesWon: 35, currentStreak:  0, maxStreak:  9),
        LeaderboardEntry(id: "m06", name: "Lucia Ferreira",   score: 1980, gamesPlayed: 42, gamesWon: 33, currentStreak:  6, maxStreak: 12),
        LeaderboardEntry(id: "m07", name: "Rafael Lima",      score: 1750, gamesPlayed: 38, gamesWon: 28, currentStreak:  2, maxStreak:  8),
        LeaderboardEntry(id: "m08", name: "Fernanda Souza",   score: 1520, gamesPlayed: 35, gamesWon: 25, currentStreak:  1, maxStreak:  7),
        LeaderboardEntry(id: "m09", name: "Bruno Martins",    score: 1380, gamesPlayed: 30, gamesWon: 21, currentStreak:  4, maxStreak:  6),
        LeaderboardEntry(id: "m10", name: "Camila Rocha",     score: 1200, gamesPlayed: 28, gamesWon: 18, currentStreak:  0, maxStreak:  5),
        LeaderboardEntry(id: "m11", name: "Thiago Nunes",     score:  980, gamesPlayed: 22, gamesWon: 14, currentStreak:  3, maxStreak:  4),
        LeaderboardEntry(id: "m12", name: "Beatriz Mendes",   score:  760, gamesPlayed: 18, gamesWon: 11, currentStreak:  1, maxStreak:  3),
    ]

    func fetchLeaderboard() async -> [LeaderboardEntry] {
        var entries = mockPlayers
        if let current = loadCurrentUser() {
            entries.append(current)
        }
        return entries.sorted { $0.score > $1.score }
    }

    func updatePlayerScore(id: String, name: String, score: Int, stats: PlayerStats) async {
        let entry = LeaderboardEntry(
            id: id,
            name: name,
            score: score,
            gamesPlayed: stats.gamesPlayed,
            gamesWon: stats.gamesWon,
            currentStreak: stats.currentStreak,
            maxStreak: stats.maxStreak,
            isCurrentUser: true
        )
        saveCurrentUser(entry)

        // Com Firebase seria algo como:
        // try? await Firestore.firestore().collection("leaderboard").document(id).setData(from: entry)
    }

    // MARK: - Persistência local
    private func loadCurrentUser() -> LeaderboardEntry? {
        guard let data = userDefaults.data(forKey: currentUserKey),
              let entry = try? JSONDecoder().decode(LeaderboardEntry.self, from: data)
        else { return nil }
        return entry
    }

    private func saveCurrentUser(_ entry: LeaderboardEntry) {
        if let data = try? JSONEncoder().encode(entry) {
            userDefaults.set(data, forKey: currentUserKey)
        }
    }
}
