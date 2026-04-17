import SwiftUI
import Combine

enum AppRoute: Hashable {
    case home
    case lobby(roomId: String)
    case game(roomId: String)
    case results(roomId: String)
    case ranking
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()
    @Published var activeSheet: SheetRoute?

    enum SheetRoute: Identifiable {
        case createRoom
        case joinRoom
        case profile

        var id: String {
            switch self {
            case .createRoom: return "createRoom"
            case .joinRoom:   return "joinRoom"
            case .profile:    return "profile"
            }
        }
    }

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func present(_ sheet: SheetRoute) {
        activeSheet = sheet
    }

    func dismissSheet() {
        activeSheet = nil
    }
}

struct MainNavigationView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    case .lobby(let roomId):
                        LobbyView(roomId: roomId)
                    case .game(let roomId):
                        GameView(roomId: roomId)
                    case .results(let roomId):
                        ResultsView(roomId: roomId)
                    case .ranking:
                        RankingView()
                    }
                }
        }
        .sheet(item: $router.activeSheet) { sheet in
            switch sheet {
            case .createRoom:
                CreateRoomSheet()
            case .joinRoom:
                JoinRoomSheet()
            case .profile:
                ProfileSheet()
            }
        }
    }
}
