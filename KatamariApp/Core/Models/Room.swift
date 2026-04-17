import Foundation

struct Room: Identifiable, Codable {
    let id: String
    var code: String
    var hostId: String
    var isPrivate: Bool
    var status: RoomStatus
    var maxPlayers: Int
    var category: WordCategory
    var players: [RoomPlayer]
    var createdAt: Date

    enum RoomStatus: String, Codable {
        case waiting, playing, finished
    }

    var isFull: Bool { players.count >= maxPlayers }
    var canStart: Bool { players.count >= 2 && status == .waiting }
    var activePlayers: [RoomPlayer] { players.filter { $0.isConnected } }
}

struct RoomPlayer: Identifiable, Codable, Hashable {
    let id: String
    var displayName: String
    var word: String?
    var hasGuessed: Bool
    var guessOrder: Int?
    var roundScore: Int
    var isConnected: Bool
    var isReady: Bool
    var isHost: Bool

    init(id: String, displayName: String, isHost: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.word = nil
        self.hasGuessed = false
        self.guessOrder = nil
        self.roundScore = 0
        self.isConnected = true
        self.isReady = false
        self.isHost = isHost
    }

    var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first).map(String.init)
        return letters.joined().uppercased()
    }

    var points: Int {
        switch guessOrder {
        case 1: return 100
        case 2: return 70
        case 3: return 50
        case .some: return 30
        case .none: return 0
        }
    }

    static func == (lhs: RoomPlayer, rhs: RoomPlayer) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
