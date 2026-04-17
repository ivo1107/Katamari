import Foundation
import Combine

protocol RoomRepositoryProtocol {
    func createRoom(hostId: String, hostName: String,
                    isPrivate: Bool, category: WordCategory,
                    maxPlayers: Int) async throws -> Room

    func joinRoom(code: String, userId: String, displayName: String) async throws -> Room
    func leaveRoom(roomId: String, userId: String) async throws
    func setPlayerReady(roomId: String, userId: String, isReady: Bool) async throws
    func startGame(roomId: String, hostId: String) async throws

    func observeRoom(roomId: String) -> AnyPublisher<Room, Error>
    func fetchPublicRooms() async throws -> [Room]
    func fetchRoom(by code: String) async throws -> Room?
}
