import SwiftUI

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var isLoading = false

    private let service: LeaderboardServiceProtocol = LeaderboardService.shared

    func load() {
        isLoading = true
        Task {
            let data = await service.fetchLeaderboard()
            entries   = data
            isLoading = false
        }
    }

    func rank(of playerId: String) -> Int? {
        entries.firstIndex(where: { $0.id == playerId || $0.isCurrentUser }).map { $0 + 1 }
    }
}
