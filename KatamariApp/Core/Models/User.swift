import Foundation

struct KatamariUser: Identifiable, Codable, Hashable {
    let id: String
    var displayName: String
    var email: String?
    var totalPoints: Int
    var gamesPlayed: Int
    var wins: Int
    var fcmToken: String?
    var createdAt: Date

    init(id: String, displayName: String, email: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.totalPoints = 0
        self.gamesPlayed = 0
        self.wins = 0
        self.fcmToken = nil
        self.createdAt = Date()
    }

    var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first).map(String.init)
        return letters.joined().uppercased()
    }

    static func == (lhs: KatamariUser, rhs: KatamariUser) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
