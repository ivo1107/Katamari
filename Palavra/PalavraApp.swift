import SwiftUI

@main
struct PalavraApp: App {
    @StateObject private var game = GameViewModel()
    @StateObject private var lb   = LeaderboardViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                .environmentObject(lb)
                .preferredColorScheme(.dark)
        }
    }
}
