import SwiftUI

struct HomeView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authRepository: FirebaseAuthRepository
    @StateObject private var viewModel = HomeViewModel(
        roomRepository: FirebaseRoomRepository(),
        authRepository: FirebaseAuthRepository()
    )

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                actionButtons
                publicRoomsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(KatamariTheme.Colors.background)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .task { await viewModel.loadPublicRooms() }
        .refreshable { await viewModel.loadPublicRooms() }
        .sheet(item: $router.activeSheet) { sheet in
            switch sheet {
            case .createRoom: CreateRoomSheet()
            case .joinRoom:   JoinRoomSheet()
            case .profile:    ProfileSheet()
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(KatamariTheme.Colors.primary.opacity(0.15))
                    .frame(width: 52, height: 52)
                Text(authRepository.currentUser?.initials ?? "?")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(KatamariTheme.Colors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Olá,")
                    .font(.subheadline)
                    .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                Text(authRepository.currentUser?.displayName ?? "Jogador")
                    .font(.title3.bold())
                    .foregroundStyle(KatamariTheme.Colors.label)
            }
            Spacer()
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            KatamariButton(
                title: "Criar Sala",
                icon: "plus.circle.fill",
                style: .primary
            ) {
                HapticService.shared.impact(.medium)
                router.present(.createRoom)
            }

            KatamariButton(
                title: "Entrar com Código",
                icon: "key.fill",
                style: .secondary
            ) {
                HapticService.shared.impact(.light)
                router.present(.joinRoom)
            }
        }
    }

    private var publicRoomsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Salas Públicas")
                    .font(.title3.bold())
                    .foregroundStyle(KatamariTheme.Colors.label)
                Spacer()
                if viewModel.isLoadingRooms {
                    ProgressView().scaleEffect(0.8)
                }
            }

            if viewModel.publicRooms.isEmpty && !viewModel.isLoadingRooms {
                emptyRoomsView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.publicRooms) { room in
                        RoomCard(room: room) {
                            joinPublicRoom(room)
                        }
                    }
                }
            }
        }
    }

    private var emptyRoomsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.slash")
                .font(.system(size: 40))
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
            Text("Nenhuma sala pública disponível.\nCrie uma nova sala!")
                .font(.subheadline)
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Text("Quem Sou Eu?")
                .font(.headline.bold())
                .foregroundStyle(KatamariTheme.Colors.primary)
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 4) {
                Button {
                    router.navigate(to: .ranking)
                } label: {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(KatamariTheme.Colors.primary)
                }
                Button {
                    router.present(.profile)
                } label: {
                    Image(systemName: "person.circle")
                        .foregroundStyle(KatamariTheme.Colors.primary)
                }
            }
        }
    }

    private func joinPublicRoom(_ room: Room) {
        guard let user = authRepository.currentUser else { return }
        HapticService.shared.impact(.medium)
        Task {
            do {
                let joined = try await FirebaseRoomRepository()
                    .joinRoom(code: room.code, userId: user.id, displayName: user.displayName)
                router.navigate(to: .lobby(roomId: joined.id))
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}

struct RoomCard: View {
    let room: Room
    let onJoin: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(KatamariTheme.Colors.primary.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(room.category.emoji)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Sala \(room.code)")
                    .font(.headline)
                    .foregroundStyle(KatamariTheme.Colors.label)
                HStack(spacing: 8) {
                    Label("\(room.players.count)/\(room.maxPlayers)", systemImage: "person.2.fill")
                    Text("•")
                    Text(room.category.rawValue)
                }
                .font(.caption)
                .foregroundStyle(KatamariTheme.Colors.secondaryLabel)
            }

            Spacer()

            Button("Entrar", action: onJoin)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(KatamariTheme.Colors.primary)
                .cornerRadius(10)
        }
        .padding(16)
        .background(KatamariTheme.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}
