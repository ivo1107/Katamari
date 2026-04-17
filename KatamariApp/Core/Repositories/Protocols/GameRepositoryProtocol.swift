import Foundation
import Combine

protocol GameRepositoryProtocol {
    func observeGameState(roomId: String) -> AnyPublisher<GameState, Error>
    func observeRounds(roomId: String) -> AnyPublisher<[Round], Error>

    func submitQuestion(roomId: String, playerId: String, question: String) async throws
    func submitVote(roomId: String, playerId: String, vote: VoteResult) async throws
    func submitGuess(roomId: String, playerId: String, guess: String) async throws -> Bool
    func advanceRound(roomId: String) async throws
    func finishGame(roomId: String) async throws
}
