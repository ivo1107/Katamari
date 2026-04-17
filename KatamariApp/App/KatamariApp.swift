import SwiftUI
import FirebaseCore

@main
struct KatamariApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appRouter = AppRouter()
    @StateObject private var authRepository = FirebaseAuthRepository()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environmentObject(appRouter)
                .environmentObject(authRepository)
                .preferredColorScheme(nil)
        }
    }
}

struct ContentRootView: View {
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var authRepository: FirebaseAuthRepository

    var body: some View {
        Group {
            if authRepository.isLoading {
                SplashView()
            } else if authRepository.currentUser == nil {
                LoginView()
            } else {
                MainNavigationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authRepository.currentUser == nil)
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            KatamariTheme.Colors.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(KatamariTheme.Colors.primary)
                Text("Quem Sou Eu?")
                    .font(KatamariTheme.Typography.largeTitle)
                    .foregroundStyle(KatamariTheme.Colors.label)
            }
        }
    }
}
