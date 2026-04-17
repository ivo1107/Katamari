import SwiftUI

struct CreateRoomSheet: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authRepository: FirebaseAuthRepository
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory: WordCategory = .all
    @State private var maxPlayers: Double = 6
    @State private var isPrivate = false
    @State private var isCreating = false
    @State private var errorMessage: String?

    private let roomRepository = FirebaseRoomRepository()

    var body: some View {
        NavigationStack {
            Form {
                Section("Categoria") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(WordCategory.allCases.filter { $0 != .all }) { cat in
                                CategoryChip(category: cat, isSelected: selectedCategory == cat) {
                                    selectedCategory = cat
                                    HapticService.shared.selection()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Jogadores") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Máximo de jogadores")
                            Spacer()
                            Text("\(Int(maxPlayers))")
                                .bold()
                                .foregroundStyle(KatamariTheme.Colors.primary)
                        }
                        Slider(value: $maxPlayers, in: 2...10, step: 1)
                            .tint(KatamariTheme.Colors.primary)
                    }
                }

                Section("Privacidade") {
                    Toggle("Sala Privada", isOn: $isPrivate)
                        .tint(KatamariTheme.Colors.primary)
                    if isPrivate {
                        Text("Um código único será gerado para compartilhar com amigos.")
                            .font(.caption)
                            .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Criar Sala")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") { createRoom() }
                        .bold()
                        .disabled(isCreating)
                }
            }
            .overlay {
                if isCreating {
                    ProgressView("Criando sala...")
                        .padding(32)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private func createRoom() {
        guard let user = authRepository.currentUser else { return }
        isCreating = true
        Task {
            do {
                let room = try await roomRepository.createRoom(
                    hostId: user.id, hostName: user.displayName,
                    isPrivate: isPrivate, category: selectedCategory,
                    maxPlayers: Int(maxPlayers)
                )
                HapticService.shared.notification(.success)
                dismiss()
                router.navigate(to: .lobby(roomId: room.id))
            } catch {
                errorMessage = error.localizedDescription
                HapticService.shared.notification(.error)
            }
            isCreating = false
        }
    }
}

struct JoinRoomSheet: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authRepository: FirebaseAuthRepository
    @Environment(\.dismiss) var dismiss

    @State private var code = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    private let roomRepository = FirebaseRoomRepository()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(KatamariTheme.Colors.primary)
                    Text("Digite o código da sala")
                        .font(.headline)
                    Text("Peça o código de 6 letras ao criador da sala")
                        .font(.caption)
                        .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                TextField("ABC123", text: $code)
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textCase(.uppercase)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.characters)
                    .focused($isFocused)
                    .padding(20)
                    .background(KatamariTheme.Colors.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal, 32)
                    .onChange(of: code) { _, newValue in
                        code = String(newValue.prefix(6)).uppercased()
                    }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                KatamariButton(
                    title: isJoining ? "Entrando..." : "Entrar na Sala",
                    icon: "arrow.right.circle.fill",
                    style: .primary,
                    isLoading: isJoining,
                    isDisabled: code.count < 6
                ) {
                    joinRoom()
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .navigationTitle("Entrar com Código")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear { isFocused = true }
        }
    }

    private func joinRoom() {
        guard let user = authRepository.currentUser else { return }
        isJoining = true
        errorMessage = nil
        Task {
            do {
                let room = try await roomRepository.joinRoom(
                    code: code, userId: user.id, displayName: user.displayName
                )
                HapticService.shared.notification(.success)
                dismiss()
                router.navigate(to: .lobby(roomId: room.id))
            } catch {
                errorMessage = error.localizedDescription
                HapticService.shared.notification(.error)
            }
            isJoining = false
        }
    }
}

struct ProfileSheet: View {
    @EnvironmentObject var authRepository: FirebaseAuthRepository
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        PlayerAvatar(
                            initials: authRepository.currentUser?.initials ?? "?",
                            size: 60,
                            color: KatamariTheme.Colors.primary
                        )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authRepository.currentUser?.displayName ?? "Jogador")
                                .font(.headline.bold())
                            Text(authRepository.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    HStack {
                        Label("Total de pontos", systemImage: "star.fill")
                        Spacer()
                        Text("\(authRepository.currentUser?.totalPoints ?? 0)")
                            .bold()
                            .foregroundStyle(KatamariTheme.Colors.primary)
                    }
                    HStack {
                        Label("Partidas jogadas", systemImage: "gamecontroller.fill")
                        Spacer()
                        Text("\(authRepository.currentUser?.gamesPlayed ?? 0)")
                            .bold()
                    }
                }

                Section {
                    Button(role: .destructive) {
                        try? authRepository.signOut()
                        dismiss()
                    } label: {
                        Label("Sair da conta", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}

struct CategoryChip: View {
    let category: WordCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.emoji)
                Text(category.rawValue)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? KatamariTheme.Colors.primary : KatamariTheme.Colors.cardBackground)
            .foregroundStyle(isSelected ? .white : KatamariTheme.Colors.label)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
