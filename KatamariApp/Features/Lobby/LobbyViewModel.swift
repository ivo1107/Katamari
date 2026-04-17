import Foundation
import Combine

@MainActor
final class LobbyViewModel: ObservableObject {
    @Published var room: Room?
    @Published var isStarting = false
    @Published var errorMessage: String?
    @Published var navigateToGame = false

    let roomId: String
    private let roomRepository: FirebaseRoomRepository
    private let authRepository: FirebaseAuthRepository
    private var cancellables = Set<AnyCancellable>()

    var currentUser: KatamariUser? { authRepository.currentUser }
    var isHost: Bool { room?.hostId == currentUser?.id }

    var canStart: Bool {
        guard let room else { return false }
        return isHost && room.canStart
    }

    init(roomId: String,
         roomRepository: FirebaseRoomRepository,
         authRepository: FirebaseAuthRepository) {
        self.roomId = roomId
        self.roomRepository = roomRepository
        self.authRepository = authRepository
        observeRoom()
    }

    private func observeRoom() {
        roomRepository.observeRoom(roomId: roomId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] room in
                self?.room = room
                if room.status == .playing {
                    HapticService.shared.playGameStart()
                    self?.navigateToGame = true
                }
            }
            .store(in: &cancellables)
    }

    func startGame() async {
        guard let userId = currentUser?.id else { return }
        isStarting = true
        defer { isStarting = false }
        do {
            try await roomRepository.startGame(roomId: roomId, hostId: userId)
            HapticService.shared.playGameStart()
        } catch {
            errorMessage = error.localizedDescription
            HapticService.shared.notification(.error)
        }
    }

    func setReady(_ isReady: Bool) async {
        guard let userId = currentUser?.id else { return }
        do {
            try await roomRepository.setPlayerReady(roomId: roomId, userId: userId, isReady: isReady)
            HapticService.shared.selection()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveRoom() async {
        guard let userId = currentUser?.id else { return }
        do {
            try await roomRepository.leaveRoom(roomId: roomId, userId: userId)
        } catch {}
    }

    func copyCode() {
        guard let code = room?.code else { return }
        UIPasteboard.general.string = code
        HapticService.shared.selection()
    }
}
