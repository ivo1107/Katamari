import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authRepository: FirebaseAuthRepository
    @StateObject private var viewModel: LoginViewModel
    @Environment(\.colorScheme) var colorScheme

    init() {
        // Initialized with environment object in onAppear
        _viewModel = StateObject(wrappedValue: LoginViewModel(
            authRepository: FirebaseAuthRepository()
        ))
    }

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                heroSection
                Spacer()
                loginSection
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 32)
        }
        .alert("Erro ao entrar", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                KatamariTheme.Colors.primary.opacity(0.9),
                KatamariTheme.Colors.secondary.opacity(0.7),
                KatamariTheme.Colors.background
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroSection: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
            }
            .shadow(color: KatamariTheme.Colors.primary.opacity(0.4), radius: 20, y: 10)

            VStack(spacing: 8) {
                Text("Quem Sou Eu?")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("O jogo de adivinhação multiplayer")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var loginSection: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.3)
            } else {
                appleSignInButton
            }

            Text("Ao entrar, você concorda com nossos\nTermos de Uso e Política de Privacidade.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }

    private var appleSignInButton: some View {
        Button {
            HapticService.shared.impact(.medium)
            Task { await viewModel.signInWithApple() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .semibold))
                Text("Continuar com Apple")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(colorScheme == .dark ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(colorScheme == .dark ? .white : .black)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}
