import Foundation
import Combine

protocol ScoreRepositoryProtocol {
    func fetchGlobalRanking(limit: Int) async throws -> [GlobalScore]
    func fetchUserScore(userId: String) async throws -> GlobalScore?
    func updateScore(userId: String, pointsEarned: Int, didWin: Bool) async throws
    func observeRoomRanking(roomId: String) -> AnyPublisher<[RoomPlayer], Error>
    func saveGameResult(_ result: GameResult) async throws
}
