import Foundation
import Combine

@MainActor
final class ResultsViewModel: ObservableObject {
    @Published var room: Room?
    @Published var isLoading = true
    @Published var errorMessage: String?

    let roomId: String
    private let roomRepository: FirebaseRoomRepository
    private let scoreRepository: FirebaseScoreRepository
    private let authRepository: FirebaseAuthRepository
    private var cancellables = Set<AnyCancellable>()

    var currentUserId: String? { authRepository.currentUser?.id }

    var sortedPlayers: [RoomPlayer] {
        (room?.players ?? []).sorted {
            ($0.guessOrder ?? Int.max) < ($1.guessOrder ?? Int.max)
        }
    }

    var winner: RoomPlayer? { sortedPlayers.first(where: { $0.hasGuessed }) }

    var myResult: RoomPlayer? {
        room?.players.first { $0.id == currentUserId }
    }

    init(roomId: String,
         roomRepository: FirebaseRoomRepository,
         scoreRepository: FirebaseScoreRepository,
         authRepository: FirebaseAuthRepository) {
        self.roomId = roomId
        self.roomRepository = roomRepository
        self.scoreRepository = scoreRepository
        self.authRepository = authRepository
        observeRoom()
    }

    private func observeRoom() {
        roomRepository.observeRoom(roomId: roomId)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] room in
                self?.room = room
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
}
