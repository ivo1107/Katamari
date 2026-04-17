import Foundation
import Combine
import FirebaseFirestore

final class FirebaseScoreRepository: ScoreRepositoryProtocol {
    private let db = Firestore.firestore()

    func fetchGlobalRanking(limit: Int = 50) async throws -> [GlobalScore] {
        let snapshot = try await db.collection("users")
            .order(by: "totalPoints", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.enumerated().compactMap { index, doc in
            guard var score = try? doc.data(as: GlobalScore.self) else { return nil }
            score.rank = index + 1
            return score
        }
    }

    func fetchUserScore(userId: String) async throws -> GlobalScore? {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        return try? snapshot.data(as: GlobalScore.self)
    }

    func updateScore(userId: String, pointsEarned: Int, didWin: Bool) async throws {
        let ref = db.collection("users").document(userId)
        var updates: [String: Any] = [
            "totalPoints": FieldValue.increment(Int64(pointsEarned)),
            "gamesPlayed": FieldValue.increment(Int64(1))
        ]
        if didWin { updates["wins"] = FieldValue.increment(Int64(1)) }
        try await ref.updateData(updates)
    }

    func observeRoomRanking(roomId: String) -> AnyPublisher<[RoomPlayer], Error> {
        let subject = PassthroughSubject<[RoomPlayer], Error>()
        let listener = db.collection("rooms").document(roomId)
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                guard let snapshot,
                      let room = try? snapshot.data(as: Room.self) else { return }
                let sorted = room.players.sorted {
                    ($0.guessOrder ?? Int.max) < ($1.guessOrder ?? Int.max)
                }
                subject.send(sorted)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    func saveGameResult(_ result: GameResult) async throws {
        try db.collection("gameResults").document(result.id).setData(from: result)
    }
}
