import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

@MainActor
final class FirebaseAuthRepository: AuthRepositoryProtocol {
    @Published var currentUser: KatamariUser?
    @Published var isLoading: Bool = true

    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    init() {
        setupAuthListener()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if let user {
                    self.currentUser = try? await self.fetchOrCreateUser(firebaseUser: user)
                } else {
                    self.currentUser = nil
                }
                self.isLoading = false
            }
        }
    }

    func signInWithApple() async throws -> KatamariUser {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let result = try await performAppleSignIn(request: request)
        let credential = OAuthProvider.appleCredential(
            withIDToken: result.idToken,
            rawNonce: nonce,
            fullName: result.fullName
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let user = try await fetchOrCreateUser(firebaseUser: authResult.user,
                                               fullName: result.fullName)
        currentUser = user
        return user
    }

    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }

    func updateFCMToken(_ token: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(uid).updateData(["fcmToken": token])
    }

    func deleteAccount() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(uid).delete()
        try await Auth.auth().currentUser?.delete()
        currentUser = nil
    }

    // MARK: - Private helpers

    private func fetchOrCreateUser(firebaseUser: User,
                                   fullName: PersonNameComponents? = nil) async throws -> KatamariUser {
        let ref = db.collection("users").document(firebaseUser.uid)
        let snapshot = try await ref.getDocument()

        if snapshot.exists, let data = snapshot.data() {
            return try Firestore.Decoder().decode(KatamariUser.self, from: data)
        }

        let displayName = fullName?.formatted() ?? firebaseUser.displayName ?? "Jogador"
        let newUser = KatamariUser(id: firebaseUser.uid,
                                   displayName: displayName,
                                   email: firebaseUser.email)
        try ref.setData(from: newUser)
        return newUser
    }

    private func performAppleSignIn(request: ASAuthorizationAppleIDRequest) async throws -> AppleSignInResult {
        try await withCheckedThrowingContinuation { continuation in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate(continuation: continuation)
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { byte in charset[Int(byte) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign-In helper types

struct AppleSignInResult {
    let idToken: String
    let fullName: PersonNameComponents?
}

@MainActor
private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate,
                                    ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<AppleSignInResult, Error>

    init(continuation: CheckedContinuation<AppleSignInResult, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            continuation.resume(throwing: AuthError.invalidCredential)
            return
        }
        let result = AppleSignInResult(idToken: idToken, fullName: credential.fullName)
        continuation.resume(returning: result)
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

enum AuthError: LocalizedError {
    case invalidCredential
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Credencial inválida."
        case .userNotFound:      return "Usuário não encontrado."
        }
    }
}
