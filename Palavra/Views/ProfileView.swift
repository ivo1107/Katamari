import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var editingName = false
    @State private var draftName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {

                        // ── Avatar + nome ─────────────────────────
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "538D4E"), Color(hex: "3A7A40")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 88, height: 88)
                                Text(vm.playerName.prefix(1).uppercased())
                                    .font(.system(size: 40, weight: .black))
                                    .foregroundColor(.white)
                            }

                            if editingName {
                                HStack {
                                    TextField("Seu nome", text: $draftName)
                                        .textFieldStyle(.roundedBorder)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: 200)
                                    Button("Salvar") {
                                        vm.setPlayerName(draftName)
                                        editingName = false
                                    }
                                    .foregroundColor(Color(hex: "538D4E"))
                                    .fontWeight(.semibold)
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Text(vm.playerName)
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    Button {
                                        draftName = vm.playerName
                                        editingName = true
                                    } label: {
                                        Image(systemName: "pencil.circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)

                        // ── Pontuação total ───────────────────────
                        VStack(spacing: 4) {
                            Text("\(vm.score)")
                                .font(.system(size: 60, weight: .black))
                                .foregroundColor(Color(hex: "538D4E"))
                            Text("pontos totais")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        // ── Grade de estatísticas ─────────────────
                        let stats = vm.getStats()
                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 14) {
                            StatCard(value: "\(stats.gamesPlayed)",   label: "Jogos",            icon: "gamecontroller.fill")
                            StatCard(value: "\(stats.winRate)%",      label: "Taxa de vitória",  icon: "checkmark.seal.fill")
                            StatCard(value: "\(stats.currentStreak)", label: "Sequência atual",  icon: "flame.fill")
                            StatCard(value: "\(stats.maxStreak)",     label: "Melhor sequência", icon: "star.fill")
                        }
                        .padding(.horizontal)

                        // ── Como jogar ────────────────────────────
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Como jogar")
                                .font(.headline)
                                .foregroundColor(.white)

                            HowToRow(hex: "538D4E", text: "Letra certa na posição certa")
                            HowToRow(hex: "B59F3B", text: "Letra certa na posição errada")
                            HowToRow(hex: "3A3A3C", text: "Letra não está na palavra")

                            Text("Tens **6 tentativas** para adivinhar a palavra de 5 letras. Quanto menos tentativas, mais pontos!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                        .padding()
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(14)
                        .padding(.horizontal)

                        // ── Tabela de pontos ──────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pontuação")
                                .font(.headline)
                                .foregroundColor(.white)
                            ForEach(1...6, id: \.self) { attempt in
                                HStack {
                                    Text("\(attempt) tentativa\(attempt == 1 ? "" : "s")")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("+\(vm.points(for: attempt)) pts")
                                        .font(.subheadline.bold())
                                        .foregroundColor(Color(hex: "538D4E"))
                                }
                            }
                        }
                        .padding()
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(14)
                        .padding(.horizontal)

                        Spacer(minLength: 24)
                    }
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Sub-views
private struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: "538D4E"))
            Text(value)
                .font(.title.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(14)
    }
}

private struct HowToRow: View {
    let hex: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: hex))
                .frame(width: 32, height: 32)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}
