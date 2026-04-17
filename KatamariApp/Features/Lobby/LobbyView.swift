import SwiftUI

struct LobbyView: View {
    let roomId: String
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authRepository: FirebaseAuthRepository
    @StateObject private var viewModel: LobbyViewModel

    init(roomId: String) {
        self.roomId = roomId
        _viewModel = StateObject(wrappedValue: LobbyViewModel(
            roomId: roomId,
            roomRepository: FirebaseRoomRepository(),
            authRepository: FirebaseAuthRepository()
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if let room = viewModel.room {
                ScrollView {
                    VStack(spacing: 24) {
                        roomInfoSection(room)
                        playersSection(room)
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            } else {
                ProgressView("Carregando sala...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(KatamariTheme.Colors.background)
        .overlay(alignment: .bottom) { bottomBar }
        .navigationTitle("Lobby")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar { backButton }
        .onChange(of: viewModel.navigateToGame) { _, navigating in
            if navigating { router.navigate(to: .game(roomId: roomId)) }
        }
        .alert("Erro", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func roomInfoSection(_ room: Room) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Código da Sala")
                        .font(.caption)
                        .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                    Text(room.code)
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(KatamariTheme.Colors.primary)
                }
                Spacer()
                Button {
                    viewModel.copyCode()
                } label: {
                    Label("Copiar", systemImage: "doc.on.doc.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(KatamariTheme.Colors.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(KatamariTheme.Colors.primary.opacity(0.12))
                        .cornerRadius(10)
                }
            }
            .padding(20)
            .background(KatamariTheme.Colors.cardBackground)
            .cornerRadius(16)

            HStack(spacing: 20) {
                LobbyInfoBadge(icon: room.category.emoji,
                               label: room.category.rawValue)
                Divider().frame(height: 30)
                LobbyInfoBadge(icon: "👥",
                               label: "\(room.players.count)/\(room.maxPlayers)")
                Divider().frame(height: 30)
                LobbyInfoBadge(icon: room.isPrivate ? "🔒" : "🌐",
                               label: room.isPrivate ? "Privada" : "Pública")
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(KatamariTheme.Colors.cardBackground)
            .cornerRadius(16)
        }
    }

    private func playersSection(_ room: Room) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jogadores (\(room.players.count)/\(room.maxPlayers))")
                .font(.headline)
                .foregroundStyle(KatamariTheme.Colors.label)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(room.players) { player in
                    PlayerLobbyCard(
                        player: player,
                        isCurrentUser: player.id == authRepository.currentUser?.id
                    )
                }
                ForEach(room.players.count..<room.maxPlayers, id: \.self) { _ in
                    EmptyPlayerSlot()
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            Divider()
            VStack(spacing: 12) {
                if viewModel.isHost {
                    KatamariButton(
                        title: viewModel.isStarting ? "Iniciando..." : "Iniciar Partida",
                        icon: "play.fill",
                        style: .primary,
                        isLoading: viewModel.isStarting,
                        isDisabled: !viewModel.canStart
                    ) {
                        Task { await viewModel.startGame() }
                    }
                    if let room = viewModel.room, !room.canStart {
                        Text("Aguardando pelo menos 2 jogadores")
                            .font(.caption)
                            .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                    }
                } else {
                    KatamariButton(
                        title: "Aguardando host iniciar...",
                        icon: "clock",
                        style: .secondary,
                        isDisabled: true
                    ) {}
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(KatamariTheme.Colors.background)
    }

    @ToolbarContentBuilder
    private var backButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                Task {
                    await viewModel.leaveRoom()
                    router.pop()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Sair")
                }
                .foregroundStyle(KatamariTheme.Colors.primary)
            }
        }
    }
}

struct PlayerLobbyCard: View {
    let player: RoomPlayer
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 10) {
            PlayerAvatar(initials: player.initials, size: 36,
                         color: isCurrentUser ? KatamariTheme.Colors.primary : KatamariTheme.Colors.secondary)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(isCurrentUser ? "Você" : player.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(KatamariTheme.Colors.label)
                        .lineLimit(1)
                    if player.isHost {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(KatamariTheme.Colors.accent)
                    }
                }
                Text(player.isConnected ? "Conectado" : "Desconectado")
                    .font(.caption)
                    .foregroundStyle(player.isConnected ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            isCurrentUser
                ? KatamariTheme.Colors.primary.opacity(0.1)
                : KatamariTheme.Colors.cardBackground
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? KatamariTheme.Colors.primary.opacity(0.4) : .clear, lineWidth: 1.5)
        )
    }
}

struct EmptyPlayerSlot: View {
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .strokeBorder(KatamariTheme.Colors.separator, style: StrokeStyle(lineWidth: 2, dash: [4]))
                    .frame(width: 36, height: 36)
                Image(systemName: "plus")
                    .font(.caption)
                    .foregroundStyle(KatamariTheme.Colors.separator)
            }
            Text("Aguardando...")
                .font(.caption)
                .foregroundStyle(KatamariTheme.Colors.separator)
            Spacer()
        }
        .padding(12)
        .background(KatamariTheme.Colors.cardBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

struct LobbyInfoBadge: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(icon).font(.title3)
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(KatamariTheme.Colors.label)
        }
        .frame(maxWidth: .infinity)
    }
}
