import Foundation

struct Round: Identifiable, Codable {
    let id: String
    var roundNumber: Int
    var askingPlayerId: String
    var question: String?
    var votes: [String: VoteResult]
    var result: VoteResult?
    var type: RoundType
    var createdAt: Date

    enum RoundType: String, Codable {
        case question
        case guess
    }

    init(id: String = UUID().uuidString,
         roundNumber: Int,
         askingPlayerId: String,
         type: RoundType = .question) {
        self.id = id
        self.roundNumber = roundNumber
        self.askingPlayerId = askingPlayerId
        self.question = nil
        self.votes = [:]
        self.result = nil
        self.type = type
        self.createdAt = Date()
    }

    func majorityResult(requiredVotes: Int) -> VoteResult? {
        let yesCount = votes.values.filter { $0 == .yes }.count
        let noCount  = votes.values.filter { $0 == .no  }.count
        guard yesCount + noCount >= requiredVotes else { return nil }
        return yesCount >= noCount ? .yes : .no
    }
}
