import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var publicRooms: [Room] = []
    @Published var isLoadingRooms = false
    @Published var errorMessage: String?

    private let roomRepository: FirebaseRoomRepository
    private let authRepository: FirebaseAuthRepository

    var currentUser: KatamariUser? { authRepository.currentUser }

    init(roomRepository: FirebaseRoomRepository,
         authRepository: FirebaseAuthRepository) {
        self.roomRepository = roomRepository
        self.authRepository = authRepository
    }

    func loadPublicRooms() async {
        isLoadingRooms = true
        defer { isLoadingRooms = false }
        do {
            publicRooms = try await roomRepository.fetchPublicRooms()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        try? authRepository.signOut()
    }
}
