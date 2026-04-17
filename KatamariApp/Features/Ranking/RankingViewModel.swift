import Foundation
import Combine

@MainActor
final class RankingViewModel: ObservableObject {
    @Published var globalRanking: [GlobalScore] = []
    @Published var myScore: GlobalScore?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let scoreRepository: FirebaseScoreRepository
    private let authRepository: FirebaseAuthRepository

    var currentUserId: String? { authRepository.currentUser?.id }

    init(scoreRepository: FirebaseScoreRepository,
         authRepository: FirebaseAuthRepository) {
        self.scoreRepository = scoreRepository
        self.authRepository = authRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let ranking = scoreRepository.fetchGlobalRanking(limit: 50)
            async let myScoreResult = currentUserId.map {
                scoreRepository.fetchUserScore(userId: $0)
            }

            globalRanking = try await ranking
            myScore = try await myScoreResult ?? nil

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var myRank: Int? {
        guard let uid = currentUserId else { return nil }
        return globalRanking.first(where: { $0.userId == uid })?.rank
    }
}
