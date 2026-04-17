import Foundation
import Combine

protocol AuthRepositoryProtocol: ObservableObject {
    var currentUser: KatamariUser? { get }
    var isLoading: Bool { get }

    func signInWithApple() async throws -> KatamariUser
    func signOut() throws
    func updateFCMToken(_ token: String) async throws
    func deleteAccount() async throws
}
