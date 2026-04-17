import Foundation
import Combine
import FirebaseFirestore
import FirebaseFunctions

final class FirebaseGameRepository: GameRepositoryProtocol {
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "us-central1")

    func observeGameState(roomId: String) -> AnyPublisher<GameState, Error> {
        let subject = PassthroughSubject<GameState, Error>()
        let listener = db.collection("rooms").document(roomId)
            .collection("game").document("state")
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                guard let snapshot,
                      let state = try? snapshot.data(as: GameState.self) else { return }
                subject.send(state)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    func observeRounds(roomId: String) -> AnyPublisher<[Round], Error> {
        let subject = PassthroughSubject<[Round], Error>()
        let listener = db.collection("rooms").document(roomId)
            .collection("rounds")
            .order(by: "roundNumber")
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                guard let snapshot else { return }
                let rounds = snapshot.documents.compactMap { try? $0.data(as: Round.self) }
                subject.send(rounds)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    func submitQuestion(roomId: String, playerId: String, question: String) async throws {
        let data: [String: Any] = [
            "roomId": roomId,
            "playerId": playerId,
            "question": question
        ]
        _ = try await functions.httpsCallable("submitQuestion").call(data)
    }

    func submitVote(roomId: String, playerId: String, vote: VoteResult) async throws {
        let data: [String: Any] = [
            "roomId": roomId,
            "playerId": playerId,
            "vote": vote.rawValue
        ]
        _ = try await functions.httpsCallable("submitVote").call(data)
    }

    func submitGuess(roomId: String, playerId: String, guess: String) async throws -> Bool {
        let data: [String: Any] = [
            "roomId": roomId,
            "playerId": playerId,
            "guess": guess
        ]
        let result = try await functions.httpsCallable("submitGuess").call(data)
        guard let dict = result.data as? [String: Any],
              let correct = dict["correct"] as? Bool else { return false }
        return correct
    }

    func advanceRound(roomId: String) async throws {
        let data: [String: Any] = ["roomId": roomId]
        _ = try await functions.httpsCallable("advanceRound").call(data)
    }

    func finishGame(roomId: String) async throws {
        let data: [String: Any] = ["roomId": roomId]
        _ = try await functions.httpsCallable("finishGame").call(data)
    }
}
