import Foundation
import Combine
import FirebaseFirestore
import FirebaseFunctions

final class FirebaseRoomRepository: RoomRepositoryProtocol {
    private let db = Firestore.firestore()
    private let functions = Functions.functions(region: "us-central1")

    func createRoom(hostId: String, hostName: String,
                    isPrivate: Bool, category: WordCategory,
                    maxPlayers: Int) async throws -> Room {
        let code = generateCode()
        let host = RoomPlayer(id: hostId, displayName: hostName, isHost: true)
        let room = Room(
            id: UUID().uuidString,
            code: code,
            hostId: hostId,
            isPrivate: isPrivate,
            status: .waiting,
            maxPlayers: maxPlayers,
            category: category,
            players: [host],
            createdAt: Date()
        )
        try db.collection("rooms").document(room.id).setData(from: room)
        return room
    }

    func joinRoom(code: String, userId: String, displayName: String) async throws -> Room {
        let query = db.collection("rooms")
            .whereField("code", isEqualTo: code.uppercased())
            .whereField("status", isEqualTo: RoomStatus.waiting.rawValue)
            .limit(to: 1)

        let snapshot = try await query.getDocuments()
        guard let doc = snapshot.documents.first else {
            throw RoomError.notFound
        }
        var room = try doc.data(as: Room.self)
        guard !room.isFull else { throw RoomError.full }
        guard !room.players.contains(where: { $0.id == userId }) else { return room }

        let player = RoomPlayer(id: userId, displayName: displayName)
        room.players.append(player)
        try db.collection("rooms").document(room.id).setData(from: room)
        return room
    }

    func leaveRoom(roomId: String, userId: String) async throws {
        let ref = db.collection("rooms").document(roomId)
        let snapshot = try await ref.getDocument()
        guard var room = try? snapshot.data(as: Room.self) else { return }

        room.players.removeAll { $0.id == userId }

        if room.players.isEmpty {
            try await ref.delete()
        } else {
            if room.hostId == userId, let newHost = room.players.first {
                room.hostId = newHost.id
                if let idx = room.players.firstIndex(where: { $0.id == newHost.id }) {
                    room.players[idx].isHost = true
                }
            }
            try ref.setData(from: room)
        }
    }

    func setPlayerReady(roomId: String, userId: String, isReady: Bool) async throws {
        let ref = db.collection("rooms").document(roomId)
        let snapshot = try await ref.getDocument()
        guard var room = try? snapshot.data(as: Room.self),
              let idx = room.players.firstIndex(where: { $0.id == userId }) else { return }
        room.players[idx].isReady = isReady
        try ref.setData(from: room)
    }

    func startGame(roomId: String, hostId: String) async throws {
        let data: [String: Any] = ["roomId": roomId, "hostId": hostId]
        _ = try await functions.httpsCallable("startGame").call(data)
    }

    func observeRoom(roomId: String) -> AnyPublisher<Room, Error> {
        let subject = PassthroughSubject<Room, Error>()
        let listener = db.collection("rooms").document(roomId)
            .addSnapshotListener { snapshot, error in
                if let error { subject.send(completion: .failure(error)); return }
                guard let snapshot,
                      let room = try? snapshot.data(as: Room.self) else { return }
                subject.send(room)
            }
        return subject
            .handleEvents(receiveCancel: { listener.remove() })
            .eraseToAnyPublisher()
    }

    func fetchPublicRooms() async throws -> [Room] {
        let snapshot = try await db.collection("rooms")
            .whereField("isPrivate", isEqualTo: false)
            .whereField("status", isEqualTo: Room.RoomStatus.waiting.rawValue)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Room.self) }
    }

    func fetchRoom(by code: String) async throws -> Room? {
        let snapshot = try await db.collection("rooms")
            .whereField("code", isEqualTo: code.uppercased())
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.first.flatMap { try? $0.data(as: Room.self) }
    }

    private func generateCode() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

typealias RoomStatus = Room.RoomStatus

enum RoomError: LocalizedError {
    case notFound
    case full
    case alreadyStarted
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notFound:       return "Sala não encontrada."
        case .full:           return "A sala está cheia."
        case .alreadyStarted: return "A partida já começou."
        case .unauthorized:   return "Ação não autorizada."
        }
    }
}
