import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: GameViewModel
    @EnvironmentObject var lb: LeaderboardViewModel

    var body: some View {
        Group {
            if game.playerName.isEmpty {
                SetupView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                TabView {
                    GameView()
                        .tabItem { Label("Jogar",   systemImage: "square.grid.3x3.fill") }
                        .environmentObject(game)

                    LeaderboardView()
                        .tabItem { Label("Ranking", systemImage: "trophy.fill") }
                        .environmentObject(game)
                        .environmentObject(lb)

                    ProfileView()
                        .tabItem { Label("Perfil",  systemImage: "person.circle.fill") }
                        .environmentObject(game)
                }
                .tint(Color(hex: "538D4E"))
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: game.playerName.isEmpty)
    }
}

// MARK: - Tela de configuração inicial
struct SetupView: View {
    @EnvironmentObject var game: GameViewModel
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Text("PALAVRA")
                        .font(.system(size: 52, weight: .black))
                        .foregroundColor(.white)
                        .tracking(10)
                    Text("O jogo das palavras")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // Prévia das cores
                HStack(spacing: 6) {
                    ForEach([("P", Color(hex: "538D4E")),
                             ("A", Color(hex: "B59F3B")),
                             ("L", Color(hex: "3A3A3C")),
                             ("A", Color(hex: "538D4E")),
                             ("V", Color(hex: "B59F3B"))], id: \.0) { letter, color in
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .frame(width: 48, height: 48)
                            Text(letter)
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.top, 32)

                Spacer()

                // Formulário de nome
                VStack(spacing: 16) {
                    Text("Como devo te chamar?")
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    TextField("", text: $name)
                        .placeholder(when: name.isEmpty) {
                            Text("Seu apelido...").foregroundColor(.gray)
                        }
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .focused($focused)
                        .onSubmit { save() }

                    Button(action: save) {
                        Text("Começar a jogar")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(name.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Color.gray
                                        : Color(hex: "538D4E"))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
        .onAppear { focused = true }
    }

    private func save() {
        game.setPlayerName(name)
    }
}

// MARK: - Helpers
extension View {
    func placeholder<Content: View>(when condition: Bool,
                                    @ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .center) {
            if condition { content() }
            self
        }
    }
}
