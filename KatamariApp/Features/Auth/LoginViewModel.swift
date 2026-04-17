import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authRepository: FirebaseAuthRepository

    init(authRepository: FirebaseAuthRepository) {
        self.authRepository = authRepository
    }

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await authRepository.signInWithApple()
            HapticService.shared.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
            HapticService.shared.notification(.error)
        }
    }
}
